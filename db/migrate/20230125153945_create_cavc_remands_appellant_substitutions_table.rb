class CreateCavcRemandsAppellantSubstitutionsTable < Caseflow::Migration
  def change
    create_table :cavc_remands_appellant_substitutions do |t|
      t.date       :substitution_date, comment: "Timestamp of substitution"
      t.string     :participant_id, comment: "ID of Participant"
      t.string     :substitute_participant_id, comment: "ID of Substitue Appellant"
      t.string     :remand_sorce, comment: "Source of Remand - From Add or Edit"
      t.bigint     :cavc_remands_id, comment: "Cavc Remand this is tied to"
      t.bigint     :appellant_substitutions_id, comment: "Appellant substitition this is tied to"
      t.timestamp  :created_at, comment: "Timestamp of when substitution occurred"
      t.bigint     :created_by_id, comment: "Current user who created substitution"
      t.datetime   :updated_at, comment: "Timestamp when substitution was changed"
      t.bigint     :updated_by_id, comment: "Current user who updated substitution"
    end
  end
end
