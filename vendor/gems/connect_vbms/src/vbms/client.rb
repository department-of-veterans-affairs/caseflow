module VBMS
  # rubocop:disable Metrics/ClassLength
  class Client
    attr_reader :endpoint_url

    def self.from_env_vars(logger: nil, env_name: 'test')
      env_dir = File.join(get_env('CONNECT_VBMS_ENV_DIR'), env_name)
      VBMS::Client.new(
        get_env('CONNECT_VBMS_URL'),
        env_path(env_dir, 'CONNECT_VBMS_KEYFILE'),
        env_path(env_dir, 'CONNECT_VBMS_SAML'),
        env_path(env_dir, 'CONNECT_VBMS_KEY', allow_empty: true),
        get_env('CONNECT_VBMS_KEYPASS'),
        env_path(env_dir, 'CONNECT_VBMS_CACERT', allow_empty: true),
        env_path(env_dir, 'CONNECT_VBMS_CERT', allow_empty: true),
        logger
      )
    end

    def self.get_env(env_var_name, allow_empty: false)
      value = ENV[env_var_name]
      if !allow_empty && (value.nil? || value.empty?)
        fail EnvironmentError, "#{env_var_name} must be set"
      end
      value
    end

    def self.env_path(env_dir, env_var_name, allow_empty: false)
      value = get_env(env_var_name, allow_empty: allow_empty)
      return nil if value.nil?

      File.join(env_dir, value)
    end

    def initialize(endpoint_url, keyfile, saml, key, keypass, cacert,
                   client_cert, logger = nil)
      @endpoint_url = endpoint_url
      @keyfile = keyfile
      @saml = saml
      @key = key
      @keypass = keypass
      @cacert = cacert
      @client_cert = client_cert

      @logger = logger

      http_client = HTTPClient.new
      if @key
        http_client.ssl_config.set_client_cert_file(
          @client_cert, @key, @keypass
        )
        http_client.ssl_config.set_trust_ca(@cacert)
        http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_PEER
      else
        http_client.ssl_config.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      @http_client = http_client
    end

    def log(event, data)
      @logger.log(event, data) if @logger
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def send_request(request)
      unencrypted_xml = request.render_xml

      log(
        :unencrypted_xml,
        unencrypted_body: unencrypted_xml
      )

      output = VBMS.encrypted_soap_document_xml(
        unencrypted_xml,
        @keyfile,
        @keypass,
        request.name)
      doc = Nokogiri::XML(output)
      inject_saml(doc)
      remove_must_understand(doc)

      body = create_body(request, doc)

      response = nil
      duration = Benchmark.realtime do
        response = @http_client.post(
          @endpoint_url, body: body, header: [
            [
              'Content-Type',
              'Multipart/Related; type="application/xop+xml"; '\
                'start-info="application/soap+xml"; boundary="boundary_1234"'
            ]
          ]
        )
      end

      log(
        :request,
        response_code: response.code,
        request_body: doc.to_s,
        response_body: response.body,
        request: request,
        duration: duration
      )

      if response.code != 200
        fail VBMS::HTTPError.new(response.code, response.body)
      end

      process_response(request, response)
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def send(request)
      # the Gem::Deprecate method didn't work because this method was named send
      msg = "NOTE: Client#send is deprecated and will be removed in version 1.0; use #send_request instead\n" \
            "Client.send called from #{Gem.location_of_caller.join(':')}\n"
      warn msg unless Gem::Deprecate.skip
      send_request(request)
    end

    def inject_saml(doc)
      saml_doc = Nokogiri::XML(File.read(@saml)).root
      doc.at_xpath(
        '//wsse:Security',
        wsse: 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
      ) << saml_doc
    end

    def remove_must_understand(doc)
      doc.at_xpath(
        '//wsse:Security',
        wsse: 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd'
      ).attributes['mustUnderstand'].remove
    end

    def create_body(request, doc)
      return VBMS.load_erb('request.erb').result(binding) unless request.multipart?

      filepath = request.multipart_file
      filename = File.basename(filepath)
      content = File.read(filepath)

      VBMS.load_erb('mtom_request.erb').result(binding)
    end

    def parse_xml_strictly(xml_string)
      begin
        xml = Nokogiri::XML(
          xml_string,
          nil,
          nil,
          Nokogiri::XML::ParseOptions::STRICT | Nokogiri::XML::ParseOptions::NONET
        )
      rescue Nokogiri::XML::SyntaxError
        raise SOAPError.new('Unable to parse SOAP message', xml_string)
      end
      xml
    end

    def multipart_boundary(headers)
      return nil unless headers.key?('Content-Type')
      Mail::Field.new('Content-Type', headers['Content-Type']).parameters['boundary']
    end

    def multipart_sections(response)
      boundary = multipart_boundary(response.headers)
      return if boundary.nil?
      Mail::Part.new(
        headers: response.headers,
        body: response.content
      ).body.split!(boundary).parts
    end

    def multipart?(response)
      !(response.headers['Content-Type'] =~ /^multipart/im).nil?
    end

    def get_body(response)
      if multipart?(response)
        parts = multipart_sections(response)
        unless parts.nil?
          # might consider looking for application/xml+xop payload in there
          return parts.first.body.to_s
        end
      end

      # otherwise just return the body
      response.content
    end

    def get_and_validate_body(response)
      body = get_body(response)

      # if the body is really large, we can assume it isn't an error
      return body if body.length > 10.megabytes

      # we could check the response content-type to make sure it's XML, but they don't seem
      # to send any HTTP headers back, so we'll instead rely on strict XML parsing instead
      doc = parse_xml_strictly(body)
      check_soap_errors(doc, response)

      body
    end

    def get_decrypted_data(request, response)
      body = get_and_validate_body(response)
      begin
        data = Tempfile.open('log') do |out_t|
          VBMS.decrypt_message_xml(body, @keyfile, @keypass, out_t.path)
        end
      rescue ExecutionError
        raise SOAPError.new('Unable to decrypt SOAP response', body)
      end

      log(:decrypted_message, decrypted_data: data, request: request)

      data
    end

    def process_response(request, response)
      doc = parse_xml_strictly(get_decrypted_data(request, response))
      request.handle_response(doc)
    end

    def check_soap_errors(doc, response)
      # the envelope should be the root node of the document
      soap = doc.at_xpath('/soapenv:Envelope', VBMS::XML_NAMESPACES)
      fail SOAPError.new('No SOAP envelope found in response', response.content) if
        soap.nil?

      fail SOAPError.new('SOAP Fault returned', response.content) if
        soap.at_xpath('//soapenv:Fault', VBMS::XML_NAMESPACES)
    end
  end
end
