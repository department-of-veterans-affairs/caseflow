class BackfillSupplementalClaimsTypeColumn < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
        SET type = 'Remand'
        WHERE decision_review_remanded_id IS NOT NULL
          AND decision_review_remanded_type = 'Appeal';
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
        SET type = 'SupplementalClaim';
      SQL
    end
  end
end
