# frozen_string_literal: true

class CAVCDecisionRepository
  # Potential optimization: load and store all CAVC decisions for the appeal, but only return those for the issue.
  # see https://github.com/department-of-veterans-affairs/caseflow/pull/4248/#discussion_r159923007
  def self.cavc_decisions_by_issue(vacols_id, vacols_sequence_id)
    VACOLS::CAVCCaseDecision.where(cvfolder: vacols_id, cvissseq: vacols_sequence_id).all.map do |cavc_decision|
      CAVCDecision.load_from_vacols(cavc_decision)
    end
  end

  def self.cavc_decisions_by_appeal(vacols_id)
    VACOLS::CAVCCaseDecision.where(cvfolder: vacols_id).all.map do |cavc_decision|
      CAVCDecision.load_from_vacols(cavc_decision)
    end
  end

  def self.cavc_decisions_by_appeals(vacols_ids)
    cavc_decisions_by_appeal(vacols_ids).reduce({}) do |memo, result|
      folder = result.appeal_vacols_id
      memo[folder] = (memo[folder] || []) << result
      memo
    end
  end
end
