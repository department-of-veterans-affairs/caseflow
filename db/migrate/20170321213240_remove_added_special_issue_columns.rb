class RemoveAddedSpecialIssueColumns < ActiveRecord::Migration
  def change
    remove_column :appeals, :foreign_pension_dic_mexico_central_and_south_america_caribb
    remove_column :appeals, :home_loan_guaranty
  end
end
