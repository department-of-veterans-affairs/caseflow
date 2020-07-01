class BackfillVeteranAndDependentClaimantTypes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    veterans_with_payee_code = Claimant.where(payee_code: "00", type: "Claimant")
    dependents_with_payee_code = Claimant.where.not(payee_code: ["00", nil]).where(type: "Claimant")

    veterans_with_payee_code.unscoped.in_batches do |relation|
      relation.update_all type: "VeteranClaimant"
      sleep(0.1)
    end

    dependents_with_payee_code.unscoped.in_batches do |relation|
      relation.update_all type: "DependentClaimant"
      sleep(0.1)
    end

    safety_assured do
    # Claimants might not have a payee code for appeals or non-comp decision reviews

    # Handle veteran claimants without payee code
      execute <<-SQL
        UPDATE claimants
          SET type = 'VeteranClaimant'
          FROM appeals
          WHERE
            claimants.decision_review_id = appeals.id AND claimants.decision_review_type = 'Appeal'
            AND claimants.type = 'Claimant'
            AND (appeals.veteran_is_not_claimant IS NULL OR appeals.veteran_is_not_claimant = FALSE);
      SQL

      execute <<-SQL
        UPDATE claimants
          SET type = 'VeteranClaimant'
          FROM higher_level_reviews
          WHERE
            claimants.decision_review_id = higher_level_reviews.id AND claimants.decision_review_type = 'HigherLevelReview'
            AND claimants.type = 'Claimant'
            AND (higher_level_reviews.veteran_is_not_claimant IS NULL OR higher_level_reviews.veteran_is_not_claimant = FALSE);
      SQL

      execute <<-SQL
        UPDATE claimants
          SET type = 'VeteranClaimant'
          FROM supplemental_claims
          WHERE
            claimants.decision_review_id = supplemental_claims.id AND claimants.decision_review_type = 'SupplementalClaim'
            AND claimants.type = 'Claimant'
            AND (supplemental_claims.veteran_is_not_claimant IS NULL OR supplemental_claims.veteran_is_not_claimant = FALSE);
      SQL

      execute <<-SQL
        UPDATE claimants
          SET type = 'DependentClaimant'
          FROM appeals
          WHERE
            claimants.decision_review_id = appeals.id AND claimants.decision_review_type = 'Appeal'
            AND claimants.type = 'Claimant'
            AND appeals.veteran_is_not_claimant = TRUE;
      SQL

      # Handle dependent claimants without payee code
      execute <<-SQL
        UPDATE claimants
          SET type = 'DependentClaimant'
          FROM higher_level_reviews
          WHERE
            claimants.decision_review_id = higher_level_reviews.id AND claimants.decision_review_type = 'HigherLevelReview'
            AND claimants.type = 'Claimant'
            AND higher_level_reviews.veteran_is_not_claimant = TRUE;
      SQL

      execute <<-SQL
        UPDATE claimants
          SET type = 'DependentClaimant'
          FROM supplemental_claims
          WHERE
            claimants.decision_review_id = supplemental_claims.id AND claimants.decision_review_type = 'SupplementalClaim'
            AND claimants.type = 'Claimant'
            AND supplemental_claims.veteran_is_not_claimant = TRUE;
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
