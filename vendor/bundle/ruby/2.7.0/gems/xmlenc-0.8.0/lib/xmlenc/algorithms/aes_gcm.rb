module Xmlenc
  module Algorithms
    class AESGCM
      AUTH_TAG_LEN = 16

      class << self
        def [](size)
          new(size)
        end
      end

      def initialize(size)
        @size = size
      end

      def setup(key = nil)
        @cipher= nil
        @iv    = nil
        @key   = key || cipher.random_key
        self
      end

      def decrypt(cipher_value, options = {})
        cipher.decrypt
        cipher.padding  = 0
        cipher.key      = @key
        cipher.iv       = cipher_value[0...iv_len]
        cipher.auth_tag = cipher_value[-AUTH_TAG_LEN..-1]
        cipher.update(cipher_value[iv_len..-(AUTH_TAG_LEN + 1)]) << cipher.final
      end

      def encrypt(data, options = {})
        cipher.encrypt
        cipher.key       = @key
        cipher.iv        = iv
        cipher.auth_data = ''
        iv << (cipher.update(data) << cipher.final) << cipher.auth_tag
      end

      def key
        @key
      end

      private

      def iv
        @iv ||= cipher.random_iv
      end

      def iv_len
        cipher.iv_len
      end

      def cipher
        @cipher ||= OpenSSL::Cipher.new("aes-#{@size}-gcm")
      end
    end
  end
end
