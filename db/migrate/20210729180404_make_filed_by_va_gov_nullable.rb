class MakeFiledByVaGovNullable < Caseflow::Migration
  def up
    safety_assured do
      change_column :appeals, :filed_by_va_gov, :boolean, null: true, default: nil
      change_column :higher_level_reviews, :filed_by_va_gov, :boolean, null: true, default: nil
      change_column :supplemental_claims, :filed_by_va_gov, :boolean, null: true, default: nil
    end
  end

  def down
    safety_assured do
      change_column :appeals, :filed_by_va_gov, :boolean, null: false, default: false
      change_column :higher_level_reviews, :filed_by_va_gov, :boolean, null: false, default: false
      change_column :supplemental_claims, :filed_by_va_gov, :boolean, null: false, default: false
    end
  end
end
