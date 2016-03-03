module VBMS
  module Requests
    NAMESPACES = {
      'xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/',
      'xmlns:v4' => 'http://vbms.vba.va.gov/external/eDocumentService/v4',
      'xmlns:doc' => 'http://vbms.vba.va.gov/cdm/document/v4',
      'xmlns:cdm' => 'http://vbms.vba.va.gov/cdm',
      'xmlns:xop' => 'http://www.w3.org/2004/08/xop/include'
    }

    def self.soap
      Nokogiri::XML::Builder.new do |xml|
        xml['soapenv'].Envelope(VBMS::Requests::NAMESPACES) do
          xml['soapenv'].Header
          xml['soapenv'].Body { yield(xml) }
        end
      end.to_xml
    end
  end
end
