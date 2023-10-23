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
      document_smart_search_response
    end

    private

    def document_smart_search_response
      {
        "files": [
          {
            "owner": {
              "id": "id",
              "type": "VETERAN"
            },
            "currentVersionUuid": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
            "uuid": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
            "currentVersion": {
              "systemData": {
                "uploadSource": "VBMS-UI",
                "uploadedDateTime": "2022-03-22T15:24:24",
                "mimeType": "application/pdf",
                "contentName": "bf52e49f-5351-4211-b1db-734e3d3c5b64.pdf"
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
                "modifiedDateTime": "2022-03-22T15:24:49",
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
                "dateVaReceivedDocument": "2020-02-20",
                "claimantFirstName": "claimantFirstName",
                "veteranFirstName": "veteranFirstName",
                "contentSource": "VISTA",
                "actionable": true,
                "documentCategoryId": 14,
                "claimantLastName": "claimantLastName",
                "lastOpenedDocument": false
              }
            }
          },
          {
            "owner": {
              "id": "id",
              "type": "VETERAN"
            },
            "currentVersionUuid": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
            "uuid": "046b6c7f-0b8a-43b9-b35d-6489e6daee91",
            "currentVersion": {
              "systemData": {
                "uploadSource": "VBMS-UI",
                "uploadedDateTime": "2022-03-22T15:24:24",
                "mimeType": "application/pdf",
                "contentName": "bf52e49f-5351-4211-b1db-734e3d3c5b64.pdf"
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
                "modifiedDateTime": "2022-03-22T15:24:49",
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
                "dateVaReceivedDocument": "2020-02-20",
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
        ],
        "page": {
          "totalResults": 5,
          "totalPages": 0,
          "requestedResultsPerPage": 6,
          "currentPage": 1
        }
      }.to_json
    end
  end
end
