module Xmlenc
  class EncryptedKey
    ALGORITHMS = {
        'http://www.w3.org/2001/04/xmlenc#rsa-1_5'        => Algorithms::RSA15,
        'http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p' => Algorithms::RsaOaepMgf1p
    }

    def initialize(node)
      @node = node
    end

    def document
      @node.document
    end

    def encryption_method
      at_xpath('./xenc:EncryptionMethod')
    end

    def encrypted_data
      EncryptedData.new(referenced_node)
    end

    def cipher_value
      at_xpath('./xenc:CipherData/xenc:CipherValue').content.gsub(/[\n\s]/, '')
    end

    def cipher_value=(value)
      at_xpath('./xenc:CipherData/xenc:CipherValue').content = value
    end

    def decrypt(key)
      decryptor = algorithm.new(key)
      decryptor.decrypt(Base64.decode64(cipher_value), :node => encryption_method)
    end

    def encrypt(key, data)
      encryptor = algorithm.new(key)
      encrypted = encryptor.encrypt(data, :node => encryption_method)
      self.cipher_value = Base64.encode64(encrypted)
    end

    private

    def referenced_node
      if reference_uri
        document.at_xpath("//xenc:EncryptedData[@Id='#{reference_uri}']", NAMESPACES) ||
            raise(Xmlenc::EncryptedDataNotFound.new("Encrypted data not found for: #{reference_uri}"))
      else
        @node.at_xpath('ancestor::xenc:EncryptedData', Xmlenc::NAMESPACES) ||
            raise(Xmlenc::EncryptedDataNotFound.new('Encrypted data not in ancestore element'))
      end
    end

    def reference_uri
      if at_xpath('./xenc:ReferenceList/xenc:DataReference')
        at_xpath('./xenc:ReferenceList/xenc:DataReference')['URI'][1..-1]
      else
        nil
      end
    end

    def at_xpath(xpath)
      @node.at_xpath(xpath, NAMESPACES)
    end

    def algorithm
      algorithm = encryption_method['Algorithm']
      ALGORITHMS[algorithm] ||
          raise(UnsupportedError.new("Unsupported encryption method #{algorithm}"))
    end
  end
end
