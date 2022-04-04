module Xmlenc
  class EncryptedDocument
    attr_accessor :xml

    def initialize(xml)
      @xml = xml
    end

    def document
      @document ||= Nokogiri::XML(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT)
    end

    def encrypted_keys
      document.xpath('//xenc:EncryptedKey', NAMESPACES).collect { |n| EncryptedKey.new(n) }
    end

    def decrypt(key, fail_silent = false)
      encrypted_keys.each do |encrypted_key|
        begin
          encrypted_data = encrypted_key.encrypted_data
          data_key       = encrypted_key.decrypt(key)
          encrypted_data.decrypt(data_key)
        rescue OpenSSL::PKey::RSAError => e
          raise e unless fail_silent
        end
      end
      @document.to_xml
    end
  end
end
