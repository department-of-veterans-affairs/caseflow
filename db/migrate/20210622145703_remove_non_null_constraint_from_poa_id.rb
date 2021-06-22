class RemoveNonNullConstraintFromPoaId < Caseflow::Migration
  def up
    change_column_null :appellant_substitutions, :poa_participant_id, true
  end

  def down
    change_column_null :appellant_substitutions, :poa_participant_id, false
    change_column_default :appellant_substitutions, :poa_participant_id, from: nil, to: ""
  end
end
