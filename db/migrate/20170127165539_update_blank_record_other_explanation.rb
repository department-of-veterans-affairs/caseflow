class UpdateBlankRecordOtherExplanation < ActiveRecord::Migration
  def change
    Form8.find_each do |form8|
      form8.update(record_other_explanation: "Unknown") if form8.record_other_explanation == "{}"
    end
  end
end
