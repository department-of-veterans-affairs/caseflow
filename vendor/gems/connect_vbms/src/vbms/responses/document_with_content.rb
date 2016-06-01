module VBMS
  module Responses
    class DocumentWithContent
      attr_accessor :document, :content

      def initialize(document: nil, content: nil)
        self.document = document
        self.content = content
      end

      def self.create_from_xml(el)
        document = Document.create_from_xml(el.at_xpath('//v4:document', VBMS::XML_NAMESPACES))
        content = el.at_xpath('//v4:content/ns2:data/text()', VBMS::XML_NAMESPACES).content
        content = Base64.decode64(content)

        new(document: document, content: content)
      end

      def to_h
        { document: document, content: content }
      end

      alias to_s inspect
    end
  end
end
