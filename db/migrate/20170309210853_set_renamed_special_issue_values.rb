class SetRenamedSpecialIssueValues < ActiveRecord::Migration
  def change
    Appeal.update_all 'home_loan_guaranty=home_loan_guarantee'
    Appeal.update_all 'foreign_pension_dic_mexico_central_and_south_america_caribb=foreign_pension_dic_mexico_central_and_south_american_caribb'
  end
end
