module VBMS
  module Requests
    class FetchDocumentById
      def initialize(document_id)
        @document_id = document_id
      end

      def name
        'fetchDocumentById'
      end

      def render_xml
        VBMS::Requests.soap do |xml|
          xml['v4'].fetchDocumentById do
            xml['v4'].documentId @document_id
          end
        end
      end

      def multipart?
        false
      end

      def handle_response(doc)
        el = doc.at_xpath(
          '//v4:fetchDocumentResponse/v4:result', VBMS::XML_NAMESPACES
        )

        VBMS::Responses::DocumentWithContent.create_from_xml(el)
      end
    end
  end
end
