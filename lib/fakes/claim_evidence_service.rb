# frozen_string_literal: true

class Fakes::ClaimEvidenceService
  class << self
    def document_types; end

    def get_ocr_document(doc_series_id)
      doc_series_id = Integer(doc_series_id)

      ocr_data = if doc_series_id.even?
                   <<~OCR_DATA
                     The quick brown fox jumps over the lazy dog.
                   OCR_DATA
                 else
                   <<~OCR_DATA
                     The five boxing wizards jump quickly.
                   OCR_DATA
                 end

      ocr_data
    end

    def document_smart_search(veteran_file_number, query, page_number)
      veteran_file = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(veteran_file_number)

      return document_smart_search_response(veteran_file, page_number)
    end

    private

    def document_smart_search_response(appeal, page_number)
      docs = appeal.document_fetcher.find_or_create_documents!

      files = []
      num_results = 0
      docs.each do |doc|
        doc_series_id = Integer(doc.series_id)
        next if doc_series_id.even?

        doc_data = generate_smart_search_doc_data(doc)
        files.push(doc_data)

        num_results += 1
      end

      page_summary = {
        "totalResults": num_results,
        "totalPages": num_results + 1,
        "requestedResultsPerPage": page_number,
        "currentPage": page_number
      }

      return {
        "files": files,
        "page": page_summary
      }.to_json
    end

    def generate_smart_search_doc_data(doc)
      # NOTE: Some of this data isn't correctly mapped
      # (i.e., using doc.id for the veteran id);
      # however, it is implemented this way so the data
      # is deterministic based on data already on hand.
      return {
        "owner": {
          "id": doc.id,
          "type": "VETERAN"
        },
        "currentVersionUuid": doc.vbms_document_id,
        "uuid": doc.vbms_document_id,
        "currentVersion": {
          "systemData": {
            "uploadSource": "VBMS-UI",
            "uploadedDateTime": doc.created_at,
            "mimeType": "application/pdf",
            "contentName": "#{doc.vbms_document_id}.pdf"
          },
          "providerData": {
            "notes": "This is a note.",
            "subject": "File contains evidence related to the claim.",
            "benefitTypeId": 13,
            "payeeCode": "00",
            "documentTypeId": 137,
            "claimantMiddleInitial": "claimantMiddleInitial",
            "ocrStatus": "Searchable",
            "endProductCode": "130DPNDCY",
            "claimantParticipantId": "000000000",
            "regionalProcessingOffice": "Buffalo",
            "newMail": true,
            "hasContentionAnnotation": true,
            "systemSource": "VBMS-UI",
            "claimantDateOfBirth": "2020-02-20",
            "modifiedDateTime": doc.updated_at,
            "certified": true,
            "isAnnotated": true,
            "duplicateInformation": {
              "bestCopy": true,
              "groupId": 5,
              "establishesDate": true,
              "certifiedCopy": true
            },
            "facilityCode": "Facility",
            "veteranMiddleName": "veteranMiddleName",
            "veteranSuffix": "veteranSuffix",
            "readByCurrentUser": false,
            "claimantSsn": "123-45-6789",
            "veteranLastName": "veteranLastName",
            "dateVaReceivedDocument": doc.created_at,
            "claimantFirstName": "claimantFirstName",
            "veteranFirstName": "veteranFirstName",
            "contentSource": "VISTA",
            "actionable": true,
            "documentCategoryId": 14,
            "claimantLastName": "claimantLastName",
            "lastOpenedDocument": false
          }
        }
      }
    end
  end
end
