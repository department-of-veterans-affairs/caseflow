class BackfillSupplementalClaimsTypeColumn < Caseflow::Migration
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type=(CASE WHEN decision_review_remanded_id IS NOT NULL AND decision_review_remanded_type = 'Appeal' THEN 'Remand'
                         ELSE 'SupplementalClaim'
                    END);
      SQL
    end
  end

  def down
    SupplementalClaim.in_batches.update_all type: 'SupplementalClaim'
  end
end
