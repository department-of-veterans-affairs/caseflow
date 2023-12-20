class RemoveNonNullConstraintFromPoaId < Caseflow::Migration
  def up
    change_column_null :appellant_substitutions, :poa_participant_id, true
    change_column_default :appellant_substitutions, :poa_participant_id, from: "", to: nil
  end

  def down
    change_column_default :appellant_substitutions, :poa_participant_id, from: nil, to: ""
    change_column_null :appellant_substitutions, :poa_participant_id, false, ""
  end
end
