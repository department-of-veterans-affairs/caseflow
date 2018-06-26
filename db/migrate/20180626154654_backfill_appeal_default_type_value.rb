class BackfillAppealDefaultTypeValue < ActiveRecord::Migration[5.1]
  def change
    AppealView.select(:id).find_in_batches.with_index do |records, index|
      puts "Processing batch #{index + 1}\r"
      AppealView.where(id: records).update_all(appeal_type: "LegacyAppeal")
    end

    change_column_null :appeal_views, :appeal_type, false
  end
end
