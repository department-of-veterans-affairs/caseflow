# The result of a decision at the higher court, CAVC (Court of Appeals for Veteran Claims)
# This is relevant mostly for appeals that are remanded from CAVC.
class CAVCDecision
  include ActiveModel::Model

  attr_accessor :appeal_vacols_id, :decision_date

  class << self
    attr_writer :repository

    def load_from_vacols(vacols_cavc_decision)
      return nil unless vacols_cavc_decision

      new(
        appeal_vacols_id: vacols_cavc_decision.cvfolder,
        decision_date: AppealRepository.normalize_vacols_date(vacols_cavc_decision.cvddec)
      )
    end

    def repository
      @repository ||= CAVCDecisionRepository
    end
  end
end
