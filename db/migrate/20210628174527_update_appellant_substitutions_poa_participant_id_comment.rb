class UpdateAppellantSubstitutionsPoaParticipantIdComment < Caseflow::Migration[5.2]
  def change
    change_column_comment(:appellant_substitutions, :poa_participant_id, "Identifier of the appellant's POA, if they have a CorpDB participant_id. Null if the substitute appellant has no POA.")
  end
end
