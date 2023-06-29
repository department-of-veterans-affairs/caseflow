# frozen_string_literal: true

class DecisionDocument < CaseflowRecord
  include Asyncable
  include UploadableDocument
  include HasAppealUpdatedSince
  prepend AppealDecisionMailed

  class NoFileError < StandardError; end
  class NotYetSubmitted < StandardError; end

  has_many :end_product_establishments, as: :source
  has_many :effectuations, class_name: "BoardGrantEffectuation"

  validates :citation_number, format: { with: /\AA?\d{8}\Z/i }

  attr_writer :file

  S3_SUB_BUCKET = "decisions"

  delegate :veteran, to: :appeal
  delegate :file_number, to: :veteran, prefix: true

  include BelongsToPolymorphicAppealConcern
  # Sets up belongs_to association with :appeal and provides `ama_appeal` used by `has_many` call
  belongs_to_polymorphic_appeal :appeal
  has_many :ama_decision_issues, -> { includes(:ama_decision_documents).references(:decision_documents) },
           through: :ama_appeal, source: :decision_issues

  has_many :vbms_communication_packages, as: :document

  def self.create_document!(params, mail_package)
    create!(params).tap { |document| document.add_mail_package(mail_package) }
  end

  def add_mail_package(mail_package)
    @mail_package = mail_package
  end

  def pdf_name
    appeal.external_id + ".pdf"
  end

  alias document_name pdf_name

  def decision_issues
    ama_decision_issues if appeal_type == "Appeal"
    # LegacyAppeals do not have decision_issue records
  end

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
      ProcessDecisionDocumentJob.perform_later(id, mail_package)
    end
  end

  def process!(mail_package)
    return if processed?

    fail NotYetSubmitted unless submitted_and_ready?

    attempted!
    upload_to_vbms!
    queue_mail_request_job!(mail_package) unless mail_package.nil?

    if appeal.is_a?(Appeal)
      create_board_grant_effectuations!
      fail NotImplementedError if appeal.claimant&.unrecognized_claimant?

      # We do not want to process Board Grant Effectuations or create remand supplemental claims
      # for appeals with unrecognized appellants because claim establishment
      # in VBMS will fail due to the lack of a recognized claimant participant ID
      process_board_grant_effectuations!
      appeal.create_remand_supplemental_claims!
    end

    send_outcode_email(appeal)

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

  attr_reader :mail_package

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

    response = VBMSService.upload_document_to_vbms(appeal, self)

    update!(
      uploaded_to_vbms_at: Time.zone.now,
      document_version_reference_id: response.dig(:upload_document_response, :@new_document_version_ref_id),
      document_series_reference_id: response.dig(:upload_document_response, :@document_series_ref_id)
    )
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

  def send_outcode_email(appeal)
    return if !FeatureToggle.enabled?(:send_email_for_dispatched_appeals)

    if appeal.power_of_attorney.present?
      if appeal.is_a?(Appeal)
        email_address = appeal.power_of_attorney.representative_email_address
      elsif appeal.is_a?(LegacyAppeal)
        email_address = appeal.power_of_attorney.bgs_representative_email_address
      end
      DispatchEmailJob.new(appeal: appeal, type: "dispatch", email_address: email_address).call
    else
      message = "No BVA Dispatch POA notification email was sent because no POA is defined"
      log = { class: self.class, appeal_id: appeal.id, message: message }
      Rails.logger.warn("BVADispatchEmail #{log}")
    end
  end

  # Queues mail request job if recipient info present and dispatch completed
  def queue_mail_request_job!(mail_package)
    return unless uploaded_to_vbms_at

    MailRequestJob.perform_later(self, mail_package)
    info_message = "MailRequestJob for citation #{citation_number} queued for submission to Package Manager"
    log_info(info_message)
  end

  def log_info(info_message)
    uuid = SecureRandom.uuid
    Rails.logger.info(info_message + " ID: " + uuid)
  end
end
