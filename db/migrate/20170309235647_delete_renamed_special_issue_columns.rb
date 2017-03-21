class DeleteRenamedSpecialIssueColumns < ActiveRecord::Migration
  def change
    remove_column :appeals, :home_loan_guarantee
    remove_column :appeals, :foreign_pension_dic_mexico_central_and_south_american_caribb
  end
end
