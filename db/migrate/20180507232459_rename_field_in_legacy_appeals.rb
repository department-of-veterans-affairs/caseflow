class RenameFieldInLegacyAppeals < ActiveRecord::Migration[5.1]
  def change
    rename_column :legacy_appeals, :home_loan_guarantee, :home_loan_guaranty
  end
end
