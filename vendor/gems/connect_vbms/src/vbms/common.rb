require 'open3'
require 'xmlenc'

# rubocop:disable Metrics/ModuleLength
module VBMS
  FILEDIR = File.dirname(File.absolute_path(__FILE__))
  DO_WSSE = File.join(FILEDIR, '../../src/do_wsse.sh')

  if RUBY_PLATFORM == 'java'
    require 'java'

    PROJECT_ROOT = File.dirname(File.dirname(FILEDIR))
    ['classes', 'lib/*', 'lib', 'src/main/properties'].each do |p|
      $CLASSPATH << File.join(PROJECT_ROOT, p)
    end

    Dir.entries(File.join(PROJECT_ROOT, 'lib')).each do |p|
      require File.join(PROJECT_ROOT, 'lib', p) if p.ends_with?('.jar')
    end

    java_import 'EncryptSOAPDocument'
    java_import 'DecryptMessage'
  end

  XML_NAMESPACES = {
    v4: 'http://vbms.vba.va.gov/external/eDocumentService/v4',
    ns2: 'http://vbms.vba.va.gov/cdm/document/v4',
    soapenv: 'http://schemas.xmlsoap.org/soap/envelope/',
    wsse: 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
  }

  class ClientError < StandardError
  end

  class HTTPError < ClientError
    attr_reader :code, :body

    def initialize(code, body)
      super("status_code=#{code}, body=#{body[0..250]}...")
      @code = code
      @body = body
    end
  end

  class SOAPError < ClientError
    attr_reader :body

    def initialize(msg, soap_response = nil)
      super(msg)
      @body = soap_response
    end
  end

  class EnvironmentError < ClientError
  end

  class ExecutionError < ClientError
    attr_reader :cmd, :output

    def initialize(cmd, output)
      super("Error running cmd: #{cmd}\nOutput: #{output}")
      @cmd = cmd
      @output = output
    end
  end

  private

  def self.load_erb(path)
    location = File.join(FILEDIR, '../templates', path)
    ERB.new(File.read(location))
  end

  def self.decrypt_message(infile,
                           keyfile,
                           keypass,
                           logfile,
                           ignore_timestamp = false)
    args = [DO_WSSE,
            '-i', infile,
            '-k', keyfile,
            '-p', keypass,
            '-l', logfile,
            ignore_timestamp ? '-t' : '']
    begin
      output, errors, status = Open3.capture3(*args)
    rescue TypeError
      # sometimes one of the Open3 return values is a nil and it complains about coercion
      raise ExecutionError.new(DO_WSSE + args.join(' ') + ': DecryptMessage', errors) if status != 0
    end

    fail ExecutionError.new(DO_WSSE + ' DecryptMessage', errors) if status != 0

    output
  end

  def self.decrypt_message_xml(in_xml,
                               keyfile,
                               keypass,
                               logfile,
                               ignore_timestamp = false)
    if RUBY_PLATFORM == 'java'
      begin
        return Java::DecryptMessage.decrypt(
          in_xml, keyfile, keypass, ignore_timestamp
        )
      rescue Java::OrgApacheWsSecurity::WSSecurityException => e
        raise ExecutionError.new('DecryptMessage.decrypt', e.backtrace)
      end
    else
      Tempfile.open('tmp') do |t|
        t.write(in_xml)
        t.flush
        return decrypt_message(t.path, keyfile, keypass, logfile,
                               ignore_timestamp: ignore_timestamp)
      end
    end
  end

  def self.decrypt_message_xml_ruby(encrypted_xml, keyfile_p12, keypass)
    encrypted_doc = Xmlenc::EncryptedDocument.new(encrypted_xml)

    # TODO(awong): Associate a keystore class with this API instead of
    # passing path per request. The keystore client should take in a ds:KeyInfo
    # node and know how to find the associated private key.
    encryption_key = OpenSSL::PKCS12.new(File.read(keyfile_p12), keypass)
    decrypted_doc = encrypted_doc.decrypt(encryption_key.key)

    # TODO(awong): Signature verification.
    # TODO(awong): Timestamp validation.

    decrypted_doc
  end

  def self.encrypted_soap_document(infile, keyfile, keypass, request_name)
    args = [DO_WSSE,
            '-e',
            '-i', infile,
            '-k', keyfile,
            '-p', keypass,
            '-n', request_name]
    output, errors, status = Open3.capture3(*args)

    if status != 0
      fail ExecutionError.new(DO_WSSE + ' EncryptSOAPDocument', errors)
    end

    output
  end

  def self.encrypted_soap_document_xml(in_xml, keyfile, keypass, request_name)
    if RUBY_PLATFORM == 'java'
      return Java::EncryptSOAPDocument.encrypt(in_xml, keyfile, keypass, request_name)
    else
      Tempfile.open('tmp') do |t|
        t.write(in_xml)
        t.flush
        return encrypted_soap_document(t.path, keyfile, keypass, request_name)
      end
    end
  end
end
