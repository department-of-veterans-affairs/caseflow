class DisallowNilInClaimsFolderAndAppealViews < ActiveRecord::Migration[5.1]
  def change
    change_column_null :claims_folder_searches, :appeal_type, false
    change_column_null :appeal_views, :appeal_type, false
  end
end
