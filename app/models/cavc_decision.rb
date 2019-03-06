# frozen_string_literal: true

# The result of a decision on an *issue* at the higher court, CAVC (Court of Appeals for Veteran Claims)
# This is relevant mostly for appeals that are remanded from CAVC.
class CAVCDecision
  include ActiveModel::Model

  attr_accessor :appeal_vacols_id, :issue_vacols_sequence_id, :decision_date, :disposition

  DISPOSITIONS = {
    "1" => "CAVC Affirmed",
    "5" => "CAVC Dismissed",
    "6" => "CAVC Reversed",
    "7" => "CAVC Vacated and Dismissed",
    "8" => "CAVC Vacated and Remanded",
    "9" => "CAVC Settlement",
    "0" => "CAVC Abandoned",
    "D" => "CAVC Dismissed, Death"
  }.freeze

  def remanded?
    disposition == "CAVC Vacated and Remanded"
  end

  class << self
    attr_writer :repository

    def load_from_vacols(vacols_cavc_decision)
      new(
        appeal_vacols_id: vacols_cavc_decision.cvfolder,
        issue_vacols_sequence_id: vacols_cavc_decision.cvissseq,
        decision_date: AppealRepository.normalize_vacols_date(vacols_cavc_decision.cvddec),
        disposition: DISPOSITIONS[vacols_cavc_decision.cvdisp]
      )
    end

    def repository
      @repository ||= CAVCDecisionRepository
    end
  end
end
