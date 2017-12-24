class CAVCDecisionRepository
  def self.cavc_decisions_by_appeal(appeal_vacols_id)
    VACOLS::CAVCCaseDecision.where(cvfolder: appeal_vacols_id).all.map do |cavc_decision|
      CAVCDecision.load_from_vacols(cavc_decision)
    end
  end

  def self.cavc_decisions_by_appeals(vacols_ids)
    cavc = VACOLS::CAVCCaseDecision.where(cvfolder: vacols_ids).all.map do |cavc_decision|
      CAVCDecision.load_from_vacols(cavc_decision)
    end

    cavc.reduce({}) do |memo, result|
      folder = result["cvfolder"].to_s
      memo[folder] = (memo[folder] || []) << result
      memo
    end
  end
end
