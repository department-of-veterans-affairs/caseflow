# frozen_string_literal: true

class Fakes::CAVCDecisionRepository
  class << self
    attr_accessor :cavc_decision_records
  end

  def self.cavc_decisions_by_issue(vacols_id, vacols_sequence_id)
    (cavc_decision_records || []).select do |h|
      h.appeal_vacols_id == vacols_id && h.issue_vacols_sequence_id == vacols_sequence_id
    end
  end

  def self.cavc_decisions_by_appeal(vacols_id)
    (cavc_decision_records || []).select { |h| h.appeal_vacols_id == vacols_id }
  end

  def self.cavc_decisions_by_appeals(vacols_ids)
    cavc = (cavc_decision_records || []).select { |h| vacols_ids.include? h.appeal_vacols_id }

    cavc.reduce({}) do |memo, result|
      folder = result.appeal_vacols_id
      memo[folder] = (memo[folder] || []) << result
      memo
    end
  end

  def self.clean!
    self.cavc_decision_records = []
  end
end
