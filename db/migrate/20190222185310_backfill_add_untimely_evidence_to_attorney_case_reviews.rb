class BackfillAddUntimelyEvidenceToAttorneyCaseReviews < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    AttorneyCaseReview.in_batches.update_all untimely_evidence: false
  end
end