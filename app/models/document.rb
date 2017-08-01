class Document < ActiveRecord::Base
  has_many :annotations
  has_many :document_views
  has_many :documents_tags
  has_many :tags, through: :documents_tags

  # Document types are defined in the following file in
  # caseflow commons: /app/models/caseflow/document_types.rb
  # some of these names are confusing and are overriden
  # in the following table.
  TYPES_OVERRIDE = {
    "73" => "NOD",
    "95" => "SOC",
    "97" => "SSOC",
    "178" => "Form 8",
    "179" => "Form 9",
    "713" => "NOD",
    "856" => "NOD",
    "857" => "Form 9"
  }.freeze

  ALT_TYPES = {
    "Appeals - Notice of Disagreement (NOD)" => "NOD",
    "Appeals - Statement of the Case (SOC)" => "SOC",
    "Appeals - Substantive Appeal to Board of Veterans' Appeals" => "Form 9",
    "Appeals - Supplemental Statement of the Case (SSOC)" => "SSOC"
  }.freeze

  CASE_SUMMARY_TYPES = ["NOD", "SOC", "Form 9", "BVA Decision", "SSOC"]

  DECISION_TYPES = ["BVA Decision", "Remand BVA or CAVC"].freeze
  FUZZY_MATCH_DAYS = 4.days.freeze

  attr_accessor :efolder_id, :type, :alt_types, :received_at, :filename, :vacols_date

  def type?(type)
    (self.type == type) || (alt_types || []).include?(type)
  end

  def receipt_date
    received_at && received_at.to_date
  end

  def match_vbms_document_from(vbms_documents)
    match_vbms_document_using(vbms_documents) { |doc| doc.receipt_date == vacols_date }
  end

  def fuzzy_match_vbms_document_from(vbms_documents)
    match_vbms_document_using(vbms_documents) { |doc| fuzzy_date_match?(doc) }
  end

  # If a document was created with a vacols_date and merged with a matching vbms
  # document with a receipt_date, then the document is considered to be "matching"
  def matching?
    !!(received_at && vacols_date)
  end

  def self.type_from_vbms_type(vbms_type)
    TYPES_OVERRIDE[vbms_type] ||
      Caseflow::DocumentTypes::TYPES[vbms_type.to_i] ||
      :other
  end

  def self.from_efolder(hash)
    new(efolder_id: hash["id"],
        type: type_from_vbms_type(hash["type_id"]),
        received_at: hash["received_at"],
        vbms_document_id: hash["external_document_id"])
  end

  def self.from_vbms_document(vbms_document)
    new(type: type_from_vbms_type(vbms_document.doc_type),
        alt_types: (vbms_document.alt_doc_types || []).map { |type| ALT_TYPES[type] },
        received_at: vbms_document.received_at,
        vbms_document_id: vbms_document.document_id,
        filename: vbms_document.filename)
  end

  def self.type_id(type)
    TYPES_OVERRIDE.key(type) ||
      Caseflow::DocumentTypes::TYPES.key(type)
  end

  # Currently three levels of caching. Try to serve content
  # from memory, then look to S3 if it's not in memory, and
  # if it's not in S3 grab it from VBMS
  # Log where we get the file from for now for easy verification
  # of S3 integration.
  def fetch_and_cache_document_from_vbms
    @content = vbms.fetch_document_file(self)
    S3Service.store_file(file_name, @content)
    Rails.logger.info("File #{vbms_document_id} fetched from VBMS")
    @content
  end

  def fetch_content
    content = S3Service.fetch_content(file_name)
    content && Rails.logger.info("File #{vbms_document_id} fetched from S3")
    content || fetch_and_cache_document_from_vbms
  end

  def content
    @content ||= fetch_content
  end

  def serve
    File.binwrite(default_path, content)
    default_path
  end

  def file_name
    vbms_document_id.to_s
  end

  def default_path
    File.join(Rails.root, "tmp", "pdfs", file_name)
  end

  def serializable_hash(options = {})
    super({
      methods: [
        :vbms_document_id,
        :type,
        :received_at,
        :filename,
        :category_procedural,
        :category_medical,
        :category_case_summary,
        :category_other,
        :serialized_vacols_date,
        :serialized_receipt_date,
        :matching?
      ]
    }.update(options))
  end

  def to_hash
    serializable_hash
  end

  def merge_into(document)
    document.assign_attributes(
      type: type,
      alt_types: alt_types,
      received_at: received_at,
      filename: filename,
      vbms_document_id: vbms_document_id
    )

    document
  end

  def serialized_vacols_date
    serialize_date(vacols_date)
  end

  def serialized_receipt_date
    serialize_date(receipt_date)
  end

  def set_categories
    if CASE_SUMMARY_TYPES.include?(type)
      self.category_case_summary = true
    end
  end

  private

  def match_vbms_document_using(vbms_documents, &date_match_test)
    match = vbms_documents.detect do |doc|
      date_match_test.call(doc) && doc.type?(type)
    end

    match ? merge_with(match) : self
  end

  # Because VBMS does not allow the receipt date to be set after the upload date,
  # we allow it to be up to 4 days before the VACOLS date in some scenarios. In
  # these scenarios we "fuzzy match" the VBMS and VACOLS dates.
  def fuzzy_date_match?(vbms_document)
    ((vacols_date - FUZZY_MATCH_DAYS)..vacols_date).cover?(vbms_document.receipt_date)
  end

  def serialize_date(date)
    date ? date.to_formatted_s(:short_date) : ""
  end

  def merge_with(document)
    document.merge_into(self)
  end

  def vbms
    VBMSService
  end
end
