# frozen_string_literal: true

class LegacyAppealDispatch
  def initialize(appeal:, params:)
    @appeal = appeal
    @params = params.merge(appeal_id: appeal.id, appeal_type: "LegacyAppeal")
  end

  def call
    create_decision_document!(params)
  rescue ActiveRecord::RecordInvalid => error
    if error.message.match?(/^Validation failed:/)
      raise(Caseflow::Error::OutcodeValidationFailure, message: error.message)
    end

    raise error
  end

  private

  attr_reader :appeal, :params

  def create_decision_document!(params)
    DecisionDocument.create!(params).tap do |decision_document|
      delay = if decision_document.decision_date.future?
                decision_document.decision_date + DecisionDocument::PROCESS_DELAY_VBMS_OFFSET_HOURS.hours
              else
                0
              end

      decision_document.submit_for_processing!(delay: delay)

      unless decision_document.processed? || decision_document.decision_date.future?
        ProcessDecisionDocumentJob.perform_later(decision_document.id)
      end
    end
  end
end
