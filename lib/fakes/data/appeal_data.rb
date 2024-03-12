# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module Fakes::Data::AppealData
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
    @random_reader_documents ||= (0..num_documents).to_a.reduce([]) do |acc, number|
      acc << Generators::Document.build(
        vbms_document_id: number,
        type: Caseflow::DocumentTypes::TYPES.values[seeded_random.rand(Caseflow::DocumentTypes::TYPES.length)],
        category_procedural: seeded_random.rand(10) == 1,
        category_medical: seeded_random.rand(10) == 1,
        category_other: seeded_random.rand(10) == 1
      )
    end
  end

  def self.certification_ready_to_certify
    vacols_case = VACOLS::Case.where(bfcorlid: "701305078S").first
    [
      Generators::Document.build(vbms_document_id: 1, type: "NOD", received_at: vacols_case.bfdnod),
      Generators::Document.build(vbms_document_id: 2, type: "SOC", received_at: vacols_case.bfdsoc),
      Generators::Document.build(vbms_document_id: 3, type: "Form 9", received_at: vacols_case.bfd19),
      Generators::Document.build(vbms_document_id: 3, type: "SSOC", received_at: vacols_case.bfssoc1)
    ]
  end

  def self.certification_fuzzy_match_documents
    vacols_case = VACOLS::Case.where(bfcorlid: "783740847S").first
    [
      Generators::Document.build(vbms_document_id: 1, type: "NOD", received_at: vacols_case.bfdnod),
      Generators::Document.build(vbms_document_id: 2, type: "SOC", received_at: vacols_case.bfdsoc - 2.days),
      Generators::Document.build(vbms_document_id: 3, type: "Form 9", received_at: vacols_case.bfd19)
    ]
  end

  def self.certification_mismatched_documents
    [
      Generators::Document.build(vbms_document_id: 1, type: "NOD", received_at: Date.new(2015, 4, 9)),
      Generators::Document.build(vbms_document_id: 2, type: "SOC", received_at: Date.new(2011, 1, 14)),
      Generators::Document.build(vbms_document_id: 3, type: "Form 9", received_at: Date.new(2016, 7, 24))
    ]
  end

  def self.dispatch_documents
    [
      Generators::Document.build(vbms_document_id: 11, type: "BVA Decision")
    ]
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
    "VA Memo",
    "RAMP Opt-in Election"
  ].freeze

  def self.redacted_reader_documents
    @redacted_reader_documents ||= READER_REDACTED_DOCS.each_with_index.map do |doc_type, index|
      Generators::Document.build(
        vbms_document_id: (100 + index),
        type: doc_type
      )
    end
  end

  def self.document_mapping
    {
      "ready_documents" => certification_ready_to_certify,
      "fuzzy_match_documents" => certification_fuzzy_match_documents,
      "mismatched_documents" => certification_mismatched_documents,
      "static_documents" => static_reader_documents,
      "no_categories" => reader_docs_no_categories,
      "random_documents" => random_reader_documents(1000),
      "redacted_documents" => redacted_reader_documents,
      "amc_full_grants" => dispatch_documents,
      "remands_ready_for_claims_establishment" => dispatch_documents
    }
  end
end
# rubocop:enable Metrics/ModuleLength
