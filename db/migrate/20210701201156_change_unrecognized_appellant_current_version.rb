class ChangeUnrecognizedAppellantCurrentVersion < ActiveRecord::Migration[5.2]
  def up
    UnrecognizedAppellant.where(current_version: nil, created_by: nil)
      .each do |unrecognized_appellant|
      unrecognized_appellant.update(
        current_version: unrecognized_appellant,
        created_by: unrecognized_appellant.claimant.decision_review.intake.user
      )
    end
    safety_assured do
      change_column :unrecognized_appellants, :created_by_id, :bigint, null: false
    end
  end

  def down
    safety_assured do
      change_column :unrecognized_appellants, :created_by_id, :bigint, null: true
    end
  end
end
