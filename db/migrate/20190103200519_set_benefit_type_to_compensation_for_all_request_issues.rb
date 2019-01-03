class SetBenefitTypeToCompensationForAllRequestIssues < ActiveRecord::Migration[5.1]
  def change
  	RequestIssue.where(benefit_type: nil).update_all(benefit_type: "compensation")
  end
end
