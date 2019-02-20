class DecisionDocument < ApplicationRecord
  include Asyncable
  include UploadableDocument

  class NoFileError < StandardError; end
  class NotYetSubmitted < StandardError; end

  belongs_to :appeal
  has_many :end_product_establishments, as: :source
  has_many :effectuations, class_name: "BoardGrantEffectuation"

  validates :citation_number, format: { with: /\AA\d{8}\Z/i }

  attr_writer :file

  S3_SUB_BUCKET = "decisions".freeze

  delegate :veteran, to: :appeal

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
    update_decision_issue_decision_dates!
    return no_processing_required! unless upload_enabled?

    cache_file!
    super
  end

  def process!
    return if processed?

    fail NotYetSubmitted unless submitted_and_ready?

    attempted!
    upload_to_vbms!

    if FeatureToggle.enabled?(:create_board_grant_effectuations)
      create_board_grant_effectuations!
      process_board_grant_effectuations!
      appeal.create_remand_supplemental_claims!
    end

    processed!
  rescue StandardError => err
    update_error!(err.to_s)
    raise err
  end

  # Used by EndProductEstablishment to determine what modifier to use for the effectuation EPs
  def valid_modifiers
    HigherLevelReview::END_PRODUCT_MODIFIERS
  end

  # The decision document is the source for all board grant eps, so we define this method
  # to be called any time a corresponding board grant end product change statuses.
  def on_sync(end_product_establishment)
    end_product_establishment.sync_decision_issues! if end_product_establishment.status_cleared?
  end

  private

  def create_board_grant_effectuations!
    appeal.decision_issues.granted.each do |granted_decision_issue|
      BoardGrantEffectuation.find_or_create_by(granted_decision_issue: granted_decision_issue)
    end
  end

  def process_board_grant_effectuations!
    end_product_establishments.each do |end_product_establishment|
      end_product_establishment.perform!
      end_product_establishment.create_contentions!
      end_product_establishment.commit!
    end
  end

  def update_decision_issue_decision_dates!
    transaction do
      appeal.decision_issues.each do |di|
        di.update!(caseflow_decision_date: decision_date) unless di.caseflow_decision_date
      end
    end
  end

  def upload_to_vbms!
    return if uploaded_to_vbms_at

    VBMSService.upload_document_to_vbms(appeal, self)
    update!(uploaded_to_vbms_at: Time.zone.now)
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
