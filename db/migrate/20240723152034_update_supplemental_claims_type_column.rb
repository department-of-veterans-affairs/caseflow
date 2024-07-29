class UpdateSupplementalClaimsTypeColumn < Caseflow::Migration[6.0]
  def up
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type=(CASE WHEN decision_review_remanded_id IS NOT NULL THEN 'Remand'
                         ELSE 'SupplementalClaim'
                    END);
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type='';
      SQL
    end
  end
end
