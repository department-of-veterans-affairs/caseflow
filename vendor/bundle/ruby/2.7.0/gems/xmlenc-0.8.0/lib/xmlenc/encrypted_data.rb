module Xmlenc
  class EncryptedData
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

    attr_accessor :node

    def initialize(node)
      @node = node
    end

    def document
      @node.document
    end

    def encryption_method
      at_xpath('./xenc:EncryptionMethod')
    end

    def cipher_value
      at_xpath('./xenc:CipherData/xenc:CipherValue').content.gsub(/[\n\s]/, '')
    end

    def cipher_value=(value)
      at_xpath('./xenc:CipherData/xenc:CipherValue').content = value
    end

    def decrypt(key)
      decryptor = algorithm.setup(key)
      decrypted = decryptor.decrypt(Base64.decode64(cipher_value), :node => encryption_method)
      @node.replace(Nokogiri::XML::DocumentFragment.parse(decrypted)) unless @node == document.root
      decrypted
    end

    def encrypt(data)
      encryptor = algorithm.setup
      encrypted = encryptor.encrypt(data, :node => encryption_method)
      self.cipher_value = Base64.encode64(encrypted)
      encryptor.key
    end

    def type
      TYPES[@node['Type']]
    end

    private

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
