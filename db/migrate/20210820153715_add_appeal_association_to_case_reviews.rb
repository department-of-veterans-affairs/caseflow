class AddAppealAssociationToCaseReviews < Caseflow::Migration
  def change
    add_column :attorney_case_reviews, :appeal_id, :bigint, comment: "The ID of the appeal this case review is associated with"
    add_column :attorney_case_reviews, :appeal_type, :string, comment: "The type of appeal this case review is associated with"

    add_column :judge_case_reviews, :appeal_id, :bigint, comment: "The ID of the appeal this case review is associated with"
    add_column :judge_case_reviews, :appeal_type, :string, comment: "The type of appeal this case review is associated with"

    add_safe_index :attorney_case_reviews, [:appeal_type, :appeal_id], algorithm: :concurrently
    add_safe_index :judge_case_reviews, [:appeal_type, :appeal_id], algorithm: :concurrently
  end
end
