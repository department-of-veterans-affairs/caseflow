class UpdateAppellantSubstitutionsPoaParticipantIdComment < Caseflow::Migration[5.2]
  def up
    change_column_comment(:appellant_substitutions, :poa_participant_id, "Identifier of the appellant's POA, if they have a CorpDB participant_id. Null if the substitute appellant has no POA.")
  end

  def down
    change_column_comment(:appellant_substitutions, :poa_participant_id, "Identifier of the appellant's POA, if they have a CorpDB participant_id")
  end
end
