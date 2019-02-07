class AddTargetDecisionDateToAppeals < ActiveRecord::Migration[5.1]
  def change
    add_column :appeals, :target_decision_date, :date
  end
end
