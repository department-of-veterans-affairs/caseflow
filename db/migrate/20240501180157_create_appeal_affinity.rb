class CreateAppealAffinity < ActiveRecord::Migration[6.0]
  def change
    create_table :appeal_affinities do |t|
      t.string :case_id, null: false, index: { unique: true }, comment: "Appeal UUID for AMA or BRIEFF.BFKEY for Legacy"
      t.string :docket, null: false, comment: "The docket of the appeal"
      t.boolean :priority, null: false, comment: "Priority status (true/false)"
      t.datetime :affinity_start_date, null: false, comment: "The date from which to calculate an appeal's affinity window"
      t.references :distribution, foreign_key: true, null: true, comment: "The distribution which caused the affinity start date to be set, if by a distribution"

      t.timestamps
    end
  end
end
