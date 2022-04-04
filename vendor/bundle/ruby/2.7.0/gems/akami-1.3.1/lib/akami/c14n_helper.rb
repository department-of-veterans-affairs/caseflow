module Akami
  module C14nHelper
    def canonicalize(xml)
      return unless xml
      xml.canonicalize Nokogiri::XML::XML_C14N_EXCLUSIVE_1_0
    end
  end
end
