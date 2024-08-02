class BackfillSupplementalClaimsTypeColumn < Caseflow::Migration
  def up
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type=(CASE WHEN decision_review_remanded_id IS NOT NULL AND decision_review_remanded_type = 'Appeal' THEN 'Remand'
                         ELSE 'SupplementalClaim'
                    END);
      SQL

      execute <<-SQL
        CREATE VIEW remands AS
          SELECT *
          FROM supplemental_claims
          WHERE type = 'Remand';
      SQL
    end
  end

  def down
    safety_assured do
      execute <<-SQL
        UPDATE supplemental_claims
          SET type='SupplementalClaim';
      SQL

      execute <<-SQL
        DROP VIEW remands;
      SQL
    end
  end
end
