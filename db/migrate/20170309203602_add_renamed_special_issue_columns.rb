class AddRenamedSpecialIssueColumns < ActiveRecord::Migration
  def change
    add_column :appeals, :home_loan_guaranty, :boolean, default: false
    add_column :appeals, :foreign_pension_dic_mexico_central_and_south_america_caribb, :boolean, default: false
  end
end