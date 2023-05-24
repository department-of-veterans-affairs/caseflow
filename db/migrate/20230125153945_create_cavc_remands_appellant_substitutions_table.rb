class CreateCavcRemandsAppellantSubstitutionsTable < Caseflow::Migration
  def change
    create_table :cavc_remands_appellant_substitutions do |t|
      t.date       :substitution_date, comment: "Timestamp of substitution"
      t.string     :participant_id, comment: "Claimant Participant Id"
      t.string     :substitute_participant_id, comment: "Appellant Substitute participant Id"
      t.string     :remand_source, comment: "Source of Remand - From Add or Edit"
      t.bigint     :cavc_remand_id, comment: "Cavc Remand this is tied to"
      t.bigint     :appellant_substitution_id, comment: "Appellant Substitution this is tied to"
      t.boolean    :is_appellant_substituted, comment: "Y/N Boolean for active substitution"
      t.bigint     :created_by_id, comment: "Current user who created substitution"
      t.bigint     :updated_by_id, comment: "Current user who updated substitution"
      t.timestamps
    end
  end
end
