class CAVCDecisionRepository
  def self.cavc_decisions_by_appeal(appeal_vacols_id)
    VACOLS::CAVCCaseDecision.where(cvfolder: appeal_vacols_id).all.map do |cavc_decision|
      CAVCDecision.load_from_vacols(cavc_decision)
    end
  end
end
