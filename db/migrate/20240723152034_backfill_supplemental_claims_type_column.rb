class BackfillSupplementalClaimsTypeColumn < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    SupplementalClaim.in_batches do |batch|
      batch.update_all(
        <<-SQL
          SET statement_timeout = '3000s';

          UPDATE supplemental_claims SET type = 'Remand'
            WHERE decision_review_remanded_id IS NOT NULL
              AND decision_review_remanded_type = 'Appeal';

          SET statement_timeout = '30s';
        SQL
      )
    end
  end

  def down
    SupplementalClaim.in_batches.update_all type: 'SupplementalClaim'
  end
end
