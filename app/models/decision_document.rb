# frozen_string_literal: true

class DecisionDocument < CaseflowRecord
  include Asyncable
  include UploadableDocument
  include HasAppealUpdatedSince

  class NoFileError < StandardError; end
  class NotYetSubmitted < StandardError; end

  belongs_to :appeal, polymorphic: true
  has_many :end_product_establishments, as: :source
  has_many :effectuations, class_name: "BoardGrantEffectuation"

  validates :citation_number, format: { with: /\AA?\d{8}\Z/i }

  attr_writer :file

  S3_SUB_BUCKET = "decisions"

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

  def submit_for_processing!(delay: processing_delay)
    update_decision_issue_decision_dates! if appeal.is_a?(Appeal)

    cache_file!
    super

    if not_processed_or_decision_date_not_in_the_future?
      ProcessDecisionDocumentJob.perform_later(id)
    end
  end

  def process!
    return if processed?

    fail NotYetSubmitted unless submitted_and_ready?

    attempted!
    upload_to_vbms!
    create_board_grant_effectuations!

    if appeal.is_a?(Appeal)
      fail NotImplementedError if appeal.claimant.is_a?(OtherClaimant)

      process_board_grant_effectuations!
      appeal.create_remand_supplemental_claims!
    end

    processed!
  rescue StandardError => error
    update_error!(error.to_s)
    raise error
  end

  # Used by EndProductEstablishment to determine what modifier to use for the effectuation EPs
  def valid_modifiers
    HigherLevelReview::END_PRODUCT_MODIFIERS
  end

  def invalid_modifiers
    []
  end

  # The decision document is the source for all board grant eps, so we define this method
  # to be called any time a corresponding board grant end product change statuses.
  def on_sync(end_product_establishment)
    end_product_establishment.sync_decision_issues! if end_product_establishment.status_cleared?
  end

  def contention_records(epe)
    effectuations.where(end_product_establishment: epe)
  end

  def all_contention_records(epe)
    contention_records(epe)
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

  def processing_delay
    return decision_date + PROCESS_DELAY_VBMS_OFFSET_HOURS.hours if decision_date.future?

    0
  end

  def not_processed_or_decision_date_not_in_the_future?
    return true unless processed? || decision_date.future?

    false
  end
end
