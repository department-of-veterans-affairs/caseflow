class ChangeTypeRecordOtherExplanation < ActiveRecord::Migration[5.1]
  def change
    change_column :form8s, :record_other_explanation, :text
  end
end
