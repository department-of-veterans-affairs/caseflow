class BackfillVeteranAndDependentClaimantTypes < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    veterans_with_payee_code = Claimant.where(payee_code: "00", type: "Claimant")
    dependents_with_payee_code = Claimant.where.not(payee_code: ["00", nil]).where(type: "Claimant")
    claimants_without_payee_code = Claimant.where(payee_code: nil, type: "Claimant")

    veterans_with_payee_code.unscoped.in_batches do |relation|
      relation.update_all type: "VeteranClaimant"
      sleep(0.1)
    end

    dependents_with_payee_code.unscoped.in_batches do |relation|
      relation.update_all type: "DependentClaimant"
      sleep(0.1)
    end

    claimants_without_payee_code.each do |claimant|
      next unless claimant.decision_review

      if claimant.decision_review.veteran_is_not_claimant
        claimant.update!(type: "DependentClaimant")
      else
        claimant.update!(type: "VeteranClaimant")
      end
    end
  end

  def down
    Claimant.unscoped.in_batches do |relation|
      relation.update_all type: "Claimant"
      sleep(0.1)
    end
  end
end
