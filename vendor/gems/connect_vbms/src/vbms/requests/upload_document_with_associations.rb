module VBMS
  module Requests
    class UploadDocumentWithAssociations
      attr_reader :file_number

      def initialize(file_number, received_at, first_name, middle_name,
                     last_name, exam_name, pdf_file, doc_type, source, new_mail)
        @file_number = file_number
        @received_at = received_at
        @first_name = first_name
        @middle_name = middle_name
        @last_name = last_name
        @exam_name = exam_name
        @pdf_file = pdf_file
        @doc_type = doc_type
        @source = source
        @new_mail = new_mail
      end

      def name
        'uploadDocumentWithAssociations'
      end

      # received_date returns a string representing the date the document was
      # created, in the EST time zone
      #
      # According to the eDocumentService XSD, the date must be specified in
      # XML Schema date format. EST is used because that's what VBMS used in
      # their sample SoapUI projects.
      #
      # Date spec: http://www.w3.org/TR/xmlschema-2/#date
      def received_date
        @received_at.getlocal('-05:00').strftime('%Y-%m-%d-05:00')
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      def render_xml
        filename = File.basename(@pdf_file)

        VBMS::Requests.soap do |xml|
          xml['v4'].uploadDocumentWithAssociations do
            xml['v4'].document(
              externalId: '123',
              fileNumber: @file_number,
              filename: filename,
              docType: @doc_type,
              subject: @exam_name,
              veteranFirstName: @first_name,
              veteranMiddleName: @middle_name,
              veteranLastName: @last_name,
              newMail: @new_mail,
              source: @source
            ) do
              xml['doc'].receivedDt received_date
            end
            xml['v4'].documentContent do
              xml['doc'].data do
                xml['xop'].Include(href: filename)
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

      def multipart?
        true
      end

      def multipart_file
        @pdf_file
      end

      def handle_response(doc)
        doc
      end
    end
  end
end
