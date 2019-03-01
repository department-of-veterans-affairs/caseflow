class AddDecisionReviewColumnsToClaimants < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_reference :claimants, :decision_review, index: false, polymorphic: true
    add_index :claimants, [:decision_review_type, :decision_review_id], algorithm: :concurrently
  end
end
