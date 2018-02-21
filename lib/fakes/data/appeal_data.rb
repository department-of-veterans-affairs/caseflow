# rubocop:disable Metrics/ModuleLength
module Fakes::Data::AppealData
  def self.freeze_time
    Timecop.travel(Time.utc(2017, 5, 1))
    return_value = yield
    Timecop.return

    return_value
  end

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

  def self.reader_docs_no_categories
    [
      Generators::Document.build(vbms_document_id: 1, type: "NOD"),
      Generators::Document.build(vbms_document_id: 2, type: "SOC"),
      Generators::Document.build(vbms_document_id: 3, type: "Form 9"),
      Generators::Document.build(vbms_document_id: 6, type: "BVA Decision"),
      Generators::Document.build(vbms_document_id: 5, type: "Extra Reading", received_at: 60.days.ago)
    ]
  end

  def self.random_reader_documents(num_documents, seed = Random::DEFAULT.seed)
    seeded_random = Random.new(seed)
    @random_documents ||= (0..num_documents).to_a.reduce([]) do |acc, number|
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
    @redacted_documents ||= READER_REDACTED_DOCS.each_with_index.map do |doc_type, index|
      Generators::Document.build(
        vbms_document_id: (100 + index),
        type: doc_type
      )
    end
  end

  def self.certification_documents
    [
      Generators::Document.build(type: "NOD", category_procedural: true),
      Generators::Document.build(type: "SOC"),
      Generators::Document.build(type: "Form 9", category_medical: true),
      Generators::Document.build(type: "SSOC"),
      Generators::Document.build(type: "SSOC", received_at: 10.days.ago)
    ]
  end

  def self.establish_claim_documents
    freeze_time do
      certification_documents + [
        Generators::Document.build(type: "BVA Decision", received_at: 2.days.ago, category_other: true)
      ]
    end
  end

  def self.establish_claim_multiple_decisions
    freeze_time do
      establish_claim_documents + [
        Generators::Document.build(type: "BVA Decision", received_at: 2.days.ago)
      ]
    end
  end

  def self.document_mapping
    {
      "static_documents" => static_reader_documents,
      "no_categories" => reader_docs_no_categories,
      "random_documents" => random_reader_documents(1000),
      "redacted_documents" => redacted_reader_documents,
      "establish_claim" => establish_claim_documents,
      "establish_claim_multiple" => establish_claim_multiple_decisions
    }
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
        vbms_id: "123C",
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
        vacols_record: :veteran_is_appellant,
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
        veteran_date_of_birth: "1970-02-14 00:00:00 UTC".to_datetime,
        veteran_gender: "F",
        appellant_address_line_1: "303320 Rockwood Rd",
        appellant_city: "Florham Park",
        appellant_state: "NJ",
        appellant_zip: "07932",
        appellant_country: "USA",
        docket_number: "13 11-265",
        added_by_first_name: "Joe",
        added_by_middle_name: "A",
        added_by_last_name: "Snuffy",
        added_by_css_id: "MAPAPPAS",
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
        ],
        documents: random_reader_documents(7)
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_appellant,
        type: "Post Remand",
        vacols_id: "222221",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: nil,
        date_due: "2018-02-14 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "55435543",
        veteran_first_name: "Joe",
        veteran_middle_initial: nil,
        veteran_last_name: "Snuffy",
        veteran_date_of_birth: "1950-03-11 00:00:00 UTC".to_datetime,
        veteran_gender: "M",
        appellant_address_line_1: "777 Brigadoon Way",
        appellant_city: "San Jose",
        appellant_state: "CA",
        appellant_zip: "36838",
        appellant_country: "USA",
        docket_number: "13 11-265",
        added_by_first_name: nil,
        added_by_middle_name: nil,
        added_by_last_name: nil,
        added_by_css_id: nil,
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
        ],
        documents: static_reader_documents
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_appellant,
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
        veteran_date_of_birth: "1911-01-05 00:00:00 UTC".to_datetime,
        veteran_gender: "F",
        appellant_address_line_1: "8 James Ct",
        appellant_city: "Boise",
        appellant_state: "ID",
        appellant_zip: "63873",
        appellant_country: "USA",
        docket_number: "13 11-265",
        added_by_first_name: "Ricky",
        added_by_middle_name: nil,
        added_by_last_name: "Tikitembo",
        added_by_css_id: "HROBERT",
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
        ],
        documents: static_reader_documents
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
        veteran_date_of_birth: "1959-11-27 00:00:00 UTC".to_datetime,
        veteran_gender: "F",
        appellant_first_name: "Clara",
        appellant_last_name: "Ti",
        appellant_relationship: "Parent",
        appellant_address_line_1: "200 Ai Wei Way",
        appellant_city: "Fort Nixon",
        appellant_state: "PA",
        appellant_zip: "32883",
        appellant_country: "USA",
        docket_number: "13 11-265",
        added_by_first_name: "Dana",
        added_by_middle_name: "T",
        added_by_last_name: "Frey",
        added_by_css_id: "DFREY",
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
        ],
        documents: static_reader_documents
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_appellant,
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
        added_by_first_name: "Demo",
        added_by_middle_name: nil,
        added_by_last_name: "More",
        added_by_css_id: "DMORE",
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
        vacols_record: :veteran_is_appellant,
        type: "Remand",
        vacols_id: "333338",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "123846543",
        veteran_first_name: "Ann",
        veteran_middle_initial: nil,
        veteran_last_name: "Amazingveteran",
        veteran_date_of_birth: "1959-11-27 00:00:00 UTC".to_datetime,
        veteran_gender: "F",
        appellant_address_line_1: "189 Legion Dr",
        appellant_address_line_2: "Floor 5",
        appellant_city: "Roaring Springs",
        appellant_state: "MI",
        appellant_zip: "67753",
        appellant_country: "USA",
        docket_number: "13 11-265",
        added_by_first_name: nil,
        added_by_middle_name: nil,
        added_by_last_name: nil,
        added_by_css_id: nil,
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
        ],
        documents: random_reader_documents(25)
      ),
      Generators::Appeal.build(
        vacols_record: :veteran_is_appellant,
        type: "Clear and Unmistakable Error",
        vacols_id: "883335",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        date_due: "2018-02-22 00:00:00 UTC".to_datetime,
        signed_date: nil,
        vbms_id: "687878778",
        veteran_first_name: "Ruth",
        veteran_middle_initial: nil,
        veteran_last_name: "Gansburg",
        veteran_date_of_birth: "1980-03-20 00:00:00 UTC".to_datetime,
        veteran_gender: "38",
        appellant_address_line_1: "7 Springfield Rd",
        appellant_address_line_2: "Apt 2",
        appellant_city: "Ottawa",
        appellant_state: "ON",
        appellant_zip: "K1M 1C8",
        appellant_country: "CN",
        docket_number: "13 11-265",
        added_by_first_name: "Jess",
        added_by_middle_name: "P",
        added_by_last_name: "Tran",
        added_by_css_id: "HROBERT",
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
        ],
        documents: static_reader_documents
      )
    ].each(&:save)
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
# rubocop:enable Metrics/ModuleLength
