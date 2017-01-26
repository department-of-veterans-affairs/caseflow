class ChangeTypeRecordOtherExplanation < ActiveRecord::Migration
  def change
    change_column :form8s, :record_other_explanation, :text
  end
end
