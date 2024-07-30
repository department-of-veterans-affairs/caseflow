# frozen_string_literal: true

class LegacyAppealDispatch
  include ActiveModel::Model
  include DecisionDocumentValidator

  def initialize(appeal:, params:, mail_package: nil)
    @params = params.merge(appeal_id: appeal.id, appeal_type: "LegacyAppeal")
    @appeal = appeal
    @mail_package = mail_package
  end

  def call
    @success = valid?

    if success
      create_decision_document_and_submit_for_processing!(params)
      complete_root_task!
    end

    FormResponse.new(success: success, errors: [errors.full_messages.join(", ")])
  end

  private

  attr_reader :params, :appeal, :mail_package, :success

  def citation_number
    params[:citation_number]
  end

  def decision_date
    params[:decision_date]
  end

  def redacted_document_location
    params[:redacted_document_location]
  end

  def file
    params[:file]
  end

  def create_decision_document_and_submit_for_processing!(params)
    DecisionDocument.create_document!(params, mail_package).tap(&:submit_for_processing!)
  end

  def complete_root_task!
    @appeal.root_task.update!(status: Constants.TASK_STATUSES.completed)
  end
end
