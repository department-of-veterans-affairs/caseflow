class BackfillSupplementalClaimsTypeColumn < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    execute <<-SQL
      UPDATE supplemental_claims
      SET type = 'Remand'
      WHERE decision_review_remanded_id IS NOT NULL
        AND decision_review_remanded_type = 'Appeal';
    SQL
  end

  def down
    SupplementalClaim.in_batches.update_all type: 'SupplementalClaim'
  end
end
