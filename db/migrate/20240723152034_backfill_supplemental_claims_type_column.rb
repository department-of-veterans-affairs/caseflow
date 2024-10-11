class BackfillSupplementalClaimsTypeColumn < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    SupplementalClaim.in_batches do |batch|
      batch.update_all(
        <<-SQL
          type = CASE
                  WHEN decision_review_remanded_id IS NOT NULL AND decision_review_remanded_type = 'Appeal' THEN 'Remand'
                  ELSE 'SupplementalClaim'
                  END
        SQL
      )
    end
  end

  def down
    SupplementalClaim.in_batches.update_all type: 'SupplementalClaim'
  end
end
