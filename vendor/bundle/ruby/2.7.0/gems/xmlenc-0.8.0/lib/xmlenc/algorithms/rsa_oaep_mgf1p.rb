module Xmlenc
  module Algorithms
    class RsaOaepMgf1p
      DIGEST_METHODS = %w(http://www.w3.org/2000/09/xmldsig#sha1)

      def initialize(key)
        @key = key
      end

      def decrypt(cipher_value, options = {})
        verify_algorithm(options[:node]) if options[:node]
        @key.private_decrypt(cipher_value, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
      end

      def encrypt(data, options = {})
        @key.public_encrypt(data, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
      end

      private

      def verify_algorithm(node)
        digest_method = node.at_xpath('./ds:DigestMethod', NAMESPACES)['Algorithm']
        unless DIGEST_METHODS.include? digest_method
          raise UnsupportedError.new("RSA OEAP MGF1P unsupported digest method #{digest_method}")
        end
      end
    end
  end
end
