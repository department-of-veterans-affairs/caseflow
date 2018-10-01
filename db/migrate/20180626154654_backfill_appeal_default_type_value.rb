class BackfillAppealDefaultTypeValue < ActiveRecord::Migration[5.1]
  def change
    AppealView.select(:id).find_in_batches.with_index do |records, index|
      puts "Processing batch #{index + 1}\r"
      AppealView.where(id: records).update_all(appeal_type: "LegacyAppeal")
    end

    ClaimsFolderSearch.select(:id).find_in_batches.with_index do |records, index|
      puts "Processing batch #{index + 1}\r"
      ClaimsFolderSearch.where(id: records).update_all(appeal_type: "LegacyAppeal")
    end
  end
end
