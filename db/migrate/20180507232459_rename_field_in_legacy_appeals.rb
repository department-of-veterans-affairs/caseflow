class RenameFieldInLegacyAppeals < ActiveRecord::Migration[5.1]
  def change
    rename_column :legacy_appeals, :home_loan_guarantee, :home_loan_guaranty
    rename_column :legacy_appeals, :foreign_pension_dic_mexico_central_and_south_american_caribb, :foreign_pension_dic_mexico_central_and_south_america_caribb
  end
end
