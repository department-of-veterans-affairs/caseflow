# rubocop:disable Metrics/ModuleLength
module Fakes::Data::AppealData
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def self.default_vacols_ids
    default_records.map(&:vacols_id)
  end

  def self.static_reader_documents
    [
      Generators::Document.build(vbms_document_id: 1, type: "NOD", category_procedural: true),
      Generators::Document.build(vbms_document_id: 2, type: "SOC", category_medical: true),
      Generators::Document.build(vbms_document_id: 3, type: "Form 9",
                                 category_medical: true, category_procedural: true),
      Generators::Document.build(
        vbms_document_id: 5,
        type: "This is a very long document type let's see what it does to the UI!",
        received_at: 7.days.ago,
        category_other: true
      ),
      Generators::Document.build(vbms_document_id: 6, type: "BVA Decision", received_at: 8.days.ago,
                                 category_medical: true, category_procedural: true, category_other: true)
    ]
  end

  def self.random_reader_documents(num_documents, seed = Random::DEFAULT.seed)
    seeded_random = Random.new(seed)
    (0..num_documents).to_a.reduce([]) do |acc, number|
      acc << Generators::Document.build(
        vbms_document_id: number,
        type: Caseflow::DocumentTypes::TYPES.values[seeded_random.rand(Caseflow::DocumentTypes::TYPES.length)],
        category_procedural: seeded_random.rand(10) == 1,
        category_medical: seeded_random.rand(10) == 1,
        category_other: seeded_random.rand(10) == 1
      )
    end
  end

  READER_REDACTED_DOCS = [
    "VA 8 Certification of Appeal",
    "Supplemental Statement of the Case",
    "CAPRI",
    "Notice of Disagreement",
    "Rating Decision - Codesheet",
    "Rating Decision - Narrative",
    "Correspondence",
    "VA 21-526EZ, Fully Developed Claim",
    "STR - Medical",
    "Military Personnel Record",
    "Private Medical Treatment Record",
    "Map-D Development Letter",
    "Third Party Correspondence",
    "VA 9 Appeal to Board of Appeals",
    "Correspondence",
    "VA 21-4142 Authorization to Disclose Information to VA",
    "VA 21-4138 Statement in Support of Claim",
    "VA Memo"
  ].freeze

  def self.redacted_reader_documents
    READER_REDACTED_DOCS.each_with_index.map do |doc_type, index|
      Generators::Document.build(
        vbms_document_id: (100 + index),
        type: doc_type
      )
    end
  end

  def self.default_records
    [
      Generators::Appeal.build(
        type: "Court Remand",
        vacols_id: "111111",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: "2013-05-31 00:00:00 UTC".to_datetime,
        date_due: "2018-02-13 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "DEMO123",
        veteran_first_name: "Simple",
        veteran_middle_initial: "A",
        veteran_last_name: "Case",
        docket_number: "13 11-265",
        docket_date: "2014-03-25 00:00:00 UTC".to_datetime,
        regional_office_key: "RO13",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ],
        documents: static_reader_documents
      ),
      Generators::Appeal.build(
        type: "Remand",
        vacols_id: "222222",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: nil,
        date_due: "2018-02-14 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "DEMO456",
        veteran_first_name: "Large",
        veteran_middle_initial: "B",
        veteran_last_name: "Case",
        docket_number: "13 11-265",
        docket_date: "2014-03-26 00:00:00 UTC".to_datetime,
        regional_office_key: "RO13",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ],
        documents: random_reader_documents(1000)
      ),
      Generators::Appeal.build(
        type: "Remand",
        vacols_id: "333333",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "DEMO789",
        veteran_first_name: "Redacted",
        veteran_middle_initial: "C",
        veteran_last_name: "Case",
        docket_number: "13 11-265",
        docket_date: "2014-03-30 00:00:00 UTC".to_datetime,
        regional_office_key: "RO13",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ],
        documents: redacted_reader_documents
      )
    ].each(&:save)
  end

  def self.default_queue_records
    [
      Generators::Appeal.build(
        vacols_record: :veteran_is_not_appellant,
        type: "Original",
        vacols_id: "111112",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: "2013-05-31 00:00:00 UTC".to_datetime,
        date_due: "2018-02-13 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "1234",
        veteran_first_name: "Vera",
        veteran_middle_initial: "A",
        veteran_last_name: "Marshall",
        docket_number: "13 11-265",
        docket_date: "2014-03-25 00:00:00 UTC".to_datetime,
        regional_office_key: "RO30",
        representative: "Virginia Department of Veterans Affairs",
        issues: [
          {
            vacols_sequence_id: 1,
            codes: %w[02 15 03 7101],
            labels: ["Compensation",
                     "Service connection",
                     "All Others",
                     "Hypertensive vascular disease (hypertension and isolated systolic hypertension)"],
            note: "hypertension secondary to DMII."
          }
        ]
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_not_appellant,
        type: "Post Remand",
        vacols_id: "222221",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: nil,
        date_due: "2018-02-14 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "55435543",
        veteran_first_name: "Joe",
        veteran_last_name: "Snuffy",
        docket_number: "13 11-265",
        docket_date: "2014-03-26 00:00:00 UTC".to_datetime,
        regional_office_key: "RO63",
        representative: "No Representative",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 12 04 8599],
            labels: ["Compensation", "Service connection", "Schedular", "Other peripheral nerve paralysis"],
            note: "PERIPHERAL NEUROPATHY LEFT UPPER EXTREMITY 8599-8515" },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 12 04 8599],
            labels: ["Compensation", "Service connection", "All Others", "Other peripheral nerve paralysis"],
            note: "PERIPHERAL NEUROPATHY LEFT UPPER EXTREMITY 8599-8515" },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Other peripheral nerve paralysis"],
            note: "PERIPHERAL NEUROPATHY LEFT UPPER EXTREMITY 8599-8515" },
          { disposition: :remanded,
            vacols_sequence_id: 4,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Other peripheral nerve paralysis"],
            note: "PERIPHERAL NEUROPATHY LEFT UPPER EXTREMITY 8599-8515" },
          { disposition: :allowed,
            vacols_sequence_id: 5,
            codes: %w[02 15 04 7101],
            labels: ["Compensation",
                     "Service connection",
                     "New and material",
                     "Hypertensive vascular disease (hypertension and isolated systolic hypertension)"] }
        ]
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_not_appellant,
        type: "Court Remand",
        vacols_id: "333334",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "654353253",
        veteran_first_name: "Andrea",
        veteran_middle_initial: "C",
        veteran_last_name: "Rasti",
        docket_number: "13 11-265",
        docket_date: "2014-03-30 00:00:00 UTC".to_datetime,
        regional_office_key: "RO73",
        representative: "One Time Representative",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ]
      ),
      Generators::Appeal.build(
        type: "Original",
        vacols_id: "533333",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "654325324",
        veteran_first_name: "Ricky",
        veteran_last_name: "Tikitembo",
        appellant_first_name: "Clara",
        appellant_last_name: "Ti",
        docket_number: "13 11-265",
        docket_date: "2014-03-30 00:00:00 UTC".to_datetime,
        regional_office_key: "RO29",
        representative: "Agent",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ]
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_not_appellant,
        type: "Reconsideration",
        vacols_id: "333336",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "659875324",
        veteran_first_name: "Daniel",
        veteran_last_name: "Nino",
        docket_number: "13 11-265",
        docket_date: "2014-03-30 00:00:00 UTC".to_datetime,
        regional_office_key: "RO13",
        representative: "Disabled American Veterans",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ]
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_not_appellant,
        type: "Remand",
        vacols_id: "333338",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "123846543",
        veteran_first_name: "Ann",
        veteran_last_name: "Amazingveteran",
        docket_number: "13 11-265",
        docket_date: "2014-03-30 00:00:00 UTC".to_datetime,
        regional_office_key: "RO14",
        issues: [
          { disposition: :remanded,
            vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ]
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_not_appellant,
        type: "Clear and Unmistakable Error",
        vacols_id: "883335",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "687878778",
        veteran_first_name: "Ruth",
        veteran_last_name: "Gansburg",
        docket_number: "13 11-265",
        docket_date: "2014-03-30 00:00:00 UTC".to_datetime,
        regional_office_key: "RO14",
        issues: [
          { vacols_sequence_id: 1,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 2,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 3,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 4,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 5,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 6,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 7,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 8,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 9,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 10,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 11,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] },
          { vacols_sequence_id: 12,
            codes: %w[02 15 03 5252],
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"] }
        ]
      )
    ].each(&:save)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
# rubocop:enable Metrics/ModuleLength
