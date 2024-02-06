class UpdateCaseDistributionLevers < ActiveRecord::Migration[5.2]
  def change
    safety_assured do
      add_column :case_distribution_levers, :lever_group_order, :integer, null: false, comment: 'determines the order that the lever appears in each section of inputs, and the order in the history table'
      rename_column :case_distribution_levers, :is_disabled, :is_disabled_in_ui
      rename_column :case_distribution_levers, :is_active, :is_toggle_active

      change_column_comment :case_distribution_levers, :is_disabled_in_ui, 'Determines behavior in the controls page'
      change_column_comment :case_distribution_levers, :algorithms_used, 'stores an array of which algorithms the lever is used in. There are some UI niceties that are implemented to indicate which algorithm is used.'
      change_column_comment :case_distribution_levers, :control_group, 'supports the exclusion table that has toggles that control multiple levers'
      change_column_comment :case_distribution_levers, :options, 'stores the options when the data type is radio or combination, it stores the value used by scripts when there is a number input present'
      change_column_comment :case_distribution_levers, :is_toggle_active, 'used for the docket time goals, otherwise it is true and unused'
    end
  end
end
