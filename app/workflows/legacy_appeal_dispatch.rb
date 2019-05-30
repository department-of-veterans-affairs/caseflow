# frozen_string_literal: true

class LegacyAppealDispatch
  def initialize(appeal:, params:)
    @appeal = appeal
    @params = params.merge(appeal_id: appeal.id, appeal_type: "LegacyAppeal")
  end

  def call
    create_decision_document_and_submit_for_processing!(params)
  rescue ActiveRecord::RecordInvalid => error
    if error.message.match?(/^Validation failed:/)
      raise(Caseflow::Error::OutcodeValidationFailure, message: error.message)
    end

    raise error
  end

  private

  attr_reader :appeal, :params

  def create_decision_document_and_submit_for_processing!(params)
    DecisionDocument.create!(params).tap(&:submit_for_processing!)
  end
end
