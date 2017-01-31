class Document
  include ActiveModel::Model

  TYPES = {
    "34" => "Correspondence",
    "73" => "NOD",
    "95" => "SOC",
    "97" => "SSOC",
    "115" => "VA 21-4138 Statement In Support of Claim",
    "178" => "Form 8",
    "179" => "Form 9",
    "475" => "Third Party Correspondence",
    "713" => "NOD",
    "856" => "NOD",
    "857" => "Form 9",
    "27"  => "BVA Decision"
  }.freeze

  ALT_TYPES = {
    "Appeals - Notice of Disagreement (NOD)" => "NOD",
    "Appeals - Statement of the Case (SOC)" => "SOC",
    "Appeals - Substantive Appeal to Board of Veterans' Appeals" => "Form 9",
    "Appeals - Supplemental Statement of the Case (SSOC)" => "SSOC"
  }.freeze

  attr_accessor :type, :alt_types, :vbms_doc_type, :received_at, :document_id

  def type?(type)
    (self.type == type) || (alt_types || []).include?(type)
  end

  def self.from_vbms_document(vbms_document)
    new(
      type: TYPES[vbms_document.doc_type] || :other,
      alt_types: (vbms_document.alt_doc_types || []).map { |type| ALT_TYPES[type] },
      received_at: vbms_document.received_at,
      document_id: vbms_document.document_id
    )
  end

  def self.type_id(type)
    TYPES.key(type)
  end

  # Currently three levels of caching. Try to serve content
  # from memory, then look to S3 if it's not in memory, and
  # if it's not in S3 grab it from VBMS
  # Log where we get the file from for now for easy verification
  # of S3 integration.
  def fetch_and_cache_document_from_vbms
    @content = Appeal.repository.fetch_document_file(self)
    S3Service.store_file(file_name, @content)
    Rails.logger.info("File #{document_id} fetched from VBMS")
    @content
  end

  def fetch_content
    content = S3Service.fetch_content(file_name)
    content && Rails.logger.info("File #{document_id} fetched from S3")
    content || fetch_and_cache_document_from_vbms
  end

  def content
    @content ||= fetch_content
  end

  def serve
    File.binwrite(default_path, content) unless File.exist?(default_path)
    default_path
  end

  def file_name
    document_id.to_s
  end

  def default_path
    File.join(Rails.root, "tmp", "pdfs", file_name)
  end
end
