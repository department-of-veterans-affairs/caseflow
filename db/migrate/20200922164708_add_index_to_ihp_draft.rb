class AddIndexToIhpDraft < Caseflow::Migration
  def change
    add_safe_index :ihp_drafts, [:appeal_id, :appeal_type, :organization_id], name: "index_ihp_drafts_on_appeal_and_organization"
  end
end
