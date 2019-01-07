class NotNullConstraintBenefitType < ActiveRecord::Migration[5.1]
  def change
  	change_column_null :request_issues, :benefit_type, false, "compensation"
  end
end
