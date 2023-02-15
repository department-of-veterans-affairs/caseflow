class AddIndexesToCavcRemandsAppellantSubstitutions < Caseflow::Migration
  def change
    add_safe_index :cavc_remands_appellant_substitutions, [:cavc_remands_id], name: "index_on_cavc_remands_id"
    add_safe_index :cavc_remands_appellant_substitutions, [:appellant_substitutions_id], name: "index_on_appellant_substitutions_id"
    add_safe_index :cavc_remands_appellant_substitutions, [:participant_id], name: "index_on_participant_id"
    add_safe_index :cavc_remands_appellant_substitutions, [:substitute_participant_id], name: "index_on_substitute_participant_id"
  end
end
