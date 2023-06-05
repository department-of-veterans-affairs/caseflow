# frozen_string_literal: true

class LegacyAppealDispatch
  include ActiveModel::Model
  include DecisionDocumentValidator

  def initialize(appeal:, params:, mail_request: nil)
    @appeal = appeal
    @params = params.merge(appeal_id: appeal.id, appeal_type: "LegacyAppeal")
    @citation_number = params[:citation_number]
    @decision_date = params[:decision_date]
    @redacted_document_location = params[:redacted_document_location]
    @file = params[:file]
    @mail_request = mail_request
  end

  def call
    @success = valid?

    if success
      create_decision_document_and_submit_for_processing!(params)
      complete_root_task!
    end

    queue_mail_request_job unless @mail_request.nil?

    FormResponse.new(success: success, errors: [errors.full_messages.join(", ")])
  end

  private

  attr_reader :appeal, :params, :success, :citation_number,
              :decision_date, :redacted_document_location, :file

  def create_decision_document_and_submit_for_processing!(params)
    DecisionDocument.create!(params).tap(&:submit_for_processing!)
  end

  def complete_root_task!
    @appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
  end

  def queue_mail_request_job
    return unless @appeal.root_task.status == Constants.TASK_STATUSES.completed

    MailRequestJob.perform_later(@file, @mail_request)
  end
end
