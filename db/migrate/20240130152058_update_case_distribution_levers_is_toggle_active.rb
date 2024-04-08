class UpdateCaseDistributionLeversIsToggleActive < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      change_column_null :case_distribution_levers, :is_toggle_active, true
    end
  end
end
