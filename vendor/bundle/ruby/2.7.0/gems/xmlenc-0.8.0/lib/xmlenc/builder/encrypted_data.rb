module Xmlenc
  module Builder
    class EncryptedData
      include Xmlenc::Builder::ComplexTypes::EncryptedType

      ALGORITHMS = {
          'http://www.w3.org/2001/04/xmlenc#tripledes-cbc' => Algorithms::DES3CBC,
          'http://www.w3.org/2001/04/xmlenc#aes128-cbc'    => Algorithms::AESCBC[128],
          'http://www.w3.org/2001/04/xmlenc#aes256-cbc'    => Algorithms::AESCBC[256],
          'http://www.w3.org/2009/xmlenc11#aes128-gcm'     => Algorithms::AESGCM[128],
          'http://www.w3.org/2009/xmlenc11#aes192-gcm'     => Algorithms::AESGCM[192],
          'http://www.w3.org/2009/xmlenc11#aes256-gcm'     => Algorithms::AESGCM[256]
      }
      TYPES = {
          'http://www.w3.org/2001/04/xmlenc#Element' => :element,
          'http://www.w3.org/2001/04/xmlenc#Content' => :content,
      }

      tag "EncryptedData"
      namespace "xenc"

      attribute :id, String, :tag => "Id"
      attribute :type, String, :tag => "Type"

      def type
        'http://www.w3.org/2001/04/xmlenc#Element'
      end

      def initialize(*args)
        options = args.extract_options!
        if options.key?(:id)
          self.id = options.delete(:id)
        else
          self.id = "_#{SecureRandom.hex(5)}"
        end
        super(*(args << options))
      end

      def encrypt(data, key_options = {})
        encryptor = algorithm.setup
        encrypted = encryptor.encrypt(data, :node => encryption_method)
        cipher_data.cipher_value = Base64.encode64(encrypted)

        key_params = { :data => encryptor.key }

        encrypted_key = EncryptedKey.new(key_params.merge(key_options))
        encrypted_key.add_data_reference(id)

        if key_options[:carried_key_name].present?
          encrypted_key.carried_key_name = key_options[:carried_key_name]
        end

        encrypted_key
      end

      def set_key_retrieval_method(retrieval_method)
        if retrieval_method
          self.key_info ||= KeyInfo.new
          self.key_info.retrieval_method = retrieval_method
        end
      end

      def set_key_name(key_name)
        if key_name
          self.key_info ||= KeyInfo.new
          self.key_info.key_name = key_name
        end
      end

      private

      def algorithm
        algorithm = encryption_method.algorithm
        ALGORITHMS[algorithm] ||
            raise(UnsupportedError.new("Unsupported encryption method #{algorithm}"))
      end
    end
  end
end
