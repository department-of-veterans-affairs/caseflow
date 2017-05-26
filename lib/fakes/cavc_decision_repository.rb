class Fakes::CAVCDecisionRepository
  class << self
    attr_accessor :cavc_decision_records
  end

  def self.cavc_decisions_by_appeal(appeal_vacols_id)
    (cavc_decision_records || []).select { |h| h.appeal_vacols_id == appeal_vacols_id }
  end

  def self.clean!
    self.cavc_decision_records = []
  end
end
