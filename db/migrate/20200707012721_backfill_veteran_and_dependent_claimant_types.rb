class BackfillVeteranAndDependentClaimantTypes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<-SQL
        UPDATE claimants
          SET type=(CASE WHEN veteran_is_not_claimant IS TRUE THEN 'DependentClaimant'
                         ELSE 'VeteranClaimant'
                    END)
          FROM appeals
          WHERE
            decision_review_id = appeals.id
            AND decision_review_type = 'Appeal'
            AND type = 'Claimant';
      SQL

      execute <<-SQL
        UPDATE claimants
          SET type=(CASE WHEN veteran_is_not_claimant IS TRUE THEN 'DependentClaimant'
                         ELSE 'VeteranClaimant'
                    END)
          FROM higher_level_reviews
          WHERE
            decision_review_id = higher_level_reviews.id
            AND decision_review_type = 'HigherLevelReview'
            AND type = 'Claimant';
      SQL

      execute <<-SQL
        UPDATE claimants
          SET type=(CASE WHEN veteran_is_not_claimant IS TRUE THEN 'DependentClaimant'
                         ELSE 'VeteranClaimant'
                    END)
          FROM supplemental_claims
          WHERE
            decision_review_id = supplemental_claims.id
            AND decision_review_type = 'SupplementalClaim'
            AND type = 'Claimant';
      SQL
    end
  end

  def down
    Claimant.unscoped.in_batches do |relation|
      relation.update_all type: "Claimant"
      sleep(0.1)
    end
  end
end
