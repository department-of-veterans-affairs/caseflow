class BackfillClaimsSearchDefaultTypeValue < ActiveRecord::Migration[5.1]
  def change
    ClaimsFolderSearch.select(:id).find_in_batches.with_index do |records, index|
      puts "Processing batch #{index + 1}\r"
      ClaimsFolderSearch.where(id: records).update_all(appeal_type: "LegacyAppeal")
    end

    change_column_null :claims_folder_searches, :appeal_type, false
  end
end
