module Akami
  class WSSE
    # Contains certs for WSSE::Signature
    class Certs

      def initialize(certs = {})
        certs.each do |key, value|
          self.send :"#{key}=", value
        end
      end

      attr_accessor :cert_file, :cert_string, :private_key_file, :private_key_string, :private_key_password

      # Returns an <tt>OpenSSL::X509::Certificate</tt> for the +cert_string+ or +cert_file+.
      def cert
        @cert ||=
          if !cert_string.nil?
            OpenSSL::X509::Certificate.new(cert_string)
          elsif !cert_file.nil?
            OpenSSL::X509::Certificate.new(File.read(cert_file))
          end
      end

      # Returns an <tt>OpenSSL::PKey::RSA</tt> for the +private_key_string+ or +private_key_file+.
      def private_key
        @private_key ||=
          if !private_key_string.nil?
            OpenSSL::PKey::RSA.new(private_key_string, private_key_password)
          elsif !private_key_file.nil?
            OpenSSL::PKey::RSA.new(File.read(private_key_file), private_key_password)
          end
      end
    end
  end
end
