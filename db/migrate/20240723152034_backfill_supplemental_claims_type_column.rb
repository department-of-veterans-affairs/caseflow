class BackFillSupplementalClaimsTypeColumn < Caseflow::Migration
  def up
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type=(CASE WHEN decision_review_remanded_id IS NOT NULL AND decision_review_type = 'Appeal' THEN 'Remand'
                         ELSE 'SupplementalClaim'
                    END);
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type='SupplementalClaim';
      SQL
    end
  end
end
