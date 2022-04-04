module Xmlenc
  module Algorithms
    class DES3CBC
      def self.setup(key)
        new(key)
      end

      def initialize(key = nil)
        @key = key || cipher.random_key
      end

      def decrypt(cipher_value, options = {})
        cipher.decrypt
        cipher.key = @key
        cipher.iv  = cipher_value[0...iv_len]
        cipher.update(cipher_value[iv_len..-1]) << cipher.final
      end

      def encrypt(data, options = {})
        cipher.encrypt
        cipher.key = @key
        cipher.iv  = iv
        iv << cipher.update(data) << cipher.final
      end

      def key
        @key
      end

      private

      def iv_len
        cipher.iv_len
      end

      def cipher
        @cipher ||= OpenSSL::Cipher.new('des-ede3-cbc')
      end
    end
  end
end
