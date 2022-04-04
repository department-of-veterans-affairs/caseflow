module Xmlenc
  module Algorithms
    class RSA15
      def initialize(key)
        @key = key
      end

      def decrypt(cipher_value, options = {})
        @key.private_decrypt(cipher_value)
      end

      def encrypt(data, option = {})
        @key.public_encrypt(data)
      end
    end
  end
end
