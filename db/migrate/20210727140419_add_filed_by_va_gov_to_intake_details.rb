class AddFiledByVaGovToIntakeDetails < ActiveRecord::Migration[5.2]
  def change
    add_column :appeals, :filed_by_va_gov, :boolean, null: false, default: false,
      comment: "Indicates whether or not this form came from VA.gov"
    add_column :higher_level_reviews, :filed_by_va_gov, :boolean, null: false, default: false,
      comment: "Indicates whether or not this form came from VA.gov"
    add_column :supplemental_claims, :filed_by_va_gov, :boolean, null: false, default: false,
      comment: "Indicates whether or not this form came from VA.gov"
  end
end
