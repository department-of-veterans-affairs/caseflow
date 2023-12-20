# frozen_string_literal: true

class AddAppealsClaimantIndexes < Caseflow::Migration
  def change
    add_safe_index :appeals, :claimant_dob
    add_safe_index :appeals, :aod_due_to_dob
  end
end
