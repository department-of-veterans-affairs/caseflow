class AddUntimelyEvidenceToAttorneyCaseReviews < ActiveRecord::Migration[5.1]
  def up
    add_column :attorney_case_reviews, :untimely_evidence, :boolean
    change_column_default :attorney_case_reviews, :untimely_evidence, false
  end

  def down
    remove_column :attorney_case_reviews, :untimely_evidence
  end
end