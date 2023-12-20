class CreateGrantedSubstitutions < Caseflow::Migration
  def change
    create_table :granted_substitutions, comment: "Store Granted Substitution form data" do |t|
      t.date "substitution_date", null: false, comment: "Date of granted substitution"
      t.references :substitute, index: false, references: :claimants, null: false, foreign_key: { to_table: :claimants }, comment: "References claimants table"
      t.string "poa_participant_id", null: false, comment: "Identifier of the appellant's POA, if they have a CorpDB participant_id"

      t.references :source_appeal, null: false, foreign_key: { to_table: :appeals }, comment: "The relevant source appeal for this substitution"
      t.references :target_appeal, null: false, foreign_key: { to_table: :appeals }, comment: "The new appeal resulting from this granted substitution"
      t.references :created_by, index: false, references: :users, null: false, foreign_key: { to_table: :users }, comment: "User that created this record"
      t.timestamps null: false, comment: "Standard created_at/updated_at timestamps"
    end
  end
end
