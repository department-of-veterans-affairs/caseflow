class DecisionDocument < ApplicationRecord
  include Asyncable
  include UploadableDocument

  class NoFileError < StandardError; end

  belongs_to :appeal
  has_many :end_product_establishments, as: :source

  validates :citation_number, format: { with: /\AA\d{8}\Z/i }

  attr_writer :file

  S3_SUB_BUCKET = "decisions".freeze
  DECISION_OUTCODING_DELAY = 3.hours

  def document_type
    "BVA Decision"
  end

  def source
    "BVA"
  end

  # We have to always download the file from s3 to make sure it exists locally
  # instead of storing it on the server and relying that it will be there
  def pdf_location
    S3Service.fetch_file(s3_location, output_location)
    output_location
  end

  def submit_for_processing!
    return no_processing_required! unless upload_enabled?

    cache_file!
    super(delay: DECISION_OUTCODING_DELAY)
  end

  def process!
    attempted!
    upload_to_vbms!
    create_board_grant_effectuations!
    process_board_grant_effectuations!
    processed!
  rescue StandardError => err
    update_error!(err.to_s)
    raise err
  end

  private

  # on create it finds or creates the appropriate end product establishment
  def create_board_grant_effectuations!
    appeal.decision_issues.each do |granted_decision_issue|
      BoardGrantEffectuation.find_or_create_by(granted_decision_issue: granted_decision_issue)
    end
  end

  def process_board_grant_effectuations!
    # for each unprocessed end product establishment, establish it and create contentions
  end

  def upload_to_vbms!
    VBMSService.upload_document_to_vbms(appeal, self)
    # set uploaded_to_vbms_at
  end

  def upload_enabled?
    FeatureToggle.enabled?(:decision_document_upload, user: RequestStore.store[:current_user])
  end

  def pdf_name
    appeal.external_id + ".pdf"
  end

  def s3_location
    DecisionDocument::S3_SUB_BUCKET + "/" + pdf_name
  end

  def output_location
    File.join(Rails.root, "tmp", "pdfs", pdf_name)
  end

  def cache_file!
    fail NoFileError unless @file
    S3Service.store_file(s3_location, Base64.decode64(@file))
  end
end
