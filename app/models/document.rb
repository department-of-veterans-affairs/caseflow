class Document
  include ActiveModel::Model

  TYPES = {
    "34" => "Correspondence",
    "73" => "NOD",
    "95" => "SOC",
    "97" => "SSOC",
    "115" => "VA 21-4138 Statement In Support of Claim",
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

  def content
    @content ||= Appeal.repository.fetch_document_file(self)
  end

  def save!
    File.binwrite(default_path, content)
  end

  def save_unless_exists!
    save! unless File.exist?(default_path)
  end

  def default_path
    File.join(Rails.root, "tmp", "pdfs", "#{type.tr(' ', '-').downcase}-#{document_id}.pdf")
  end
end
