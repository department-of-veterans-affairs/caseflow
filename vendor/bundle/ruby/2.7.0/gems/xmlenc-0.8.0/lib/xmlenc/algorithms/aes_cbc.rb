module Xmlenc
  module Algorithms
    class AESCBC
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
        cipher.padding = 0
        cipher.key     = @key
        cipher.iv      = cipher_value[0...iv_len]
        result         = cipher.update(cipher_value[iv_len..-1]) << cipher.final

        padding_size   = result.last.unpack('c').first
        result[0...-padding_size]
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

      def iv
        @iv ||= cipher.random_iv
      end

      def iv_len
        cipher.iv_len
      end

      def cipher
        @cipher ||= OpenSSL::Cipher.new("aes-#{@size}-cbc")
      end
    end
  end
end
