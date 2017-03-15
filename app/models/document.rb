class Document < ActiveRecord::Base
  has_many :annotations
  has_many :document_users

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

  enum label: {
    decisions: 0,
    veteran_submitted: 1,
    procedural: 2,
    va_medial: 3,
    layperson: 4,
    private_medical: 5
  }

  attr_accessor :type, :alt_types, :vbms_doc_type, :received_at, :filename

  def type?(type)
    (self.type == type) || (alt_types || []).include?(type)
  end

  def self.from_vbms_document(vbms_document, save_record = false)
    attributes =
      {
        type: TYPES[vbms_document.doc_type] || :other,
        alt_types: (vbms_document.alt_doc_types || []).map { |type| ALT_TYPES[type] },
        received_at: vbms_document.received_at,
        vbms_document_id: vbms_document.document_id,
        filename: vbms_document.filename
      }

    if save_record
      find_or_create_by(vbms_document_id: vbms_document.document_id).tap do |t|
        t.assign_attributes(attributes)
      end
    else
      new(attributes)
    end
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
    Rails.logger.info("File #{vbms_document_id} fetched from VBMS")
    @content
  end

  def fetch_content
    content = S3Service.fetch_content(file_name)
    content && Rails.logger.info("File #{vbms_document_id} fetched from S3")
    content || fetch_and_cache_document_from_vbms
  end

  def content
    @content ||= fetch_and_cache_document_from_vbms
  end

  def serve
    File.binwrite(default_path, content) unless File.exist?(default_path)
    default_path
  end

  def file_name
    vbms_document_id.to_s
  end

  def default_path
    File.join(Rails.root, "tmp", "pdfs", file_name)
  end

  def opened_by_user(user)
    document_user = document_users.find_by(user: user)
    document_user && document_user.viewed_at
  end

  def to_hash
    serializable_hash(
      methods: [:vbms_document_id, :type, :received_at, :filename, :label]
    )
  end
end
