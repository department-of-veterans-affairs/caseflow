class AddSelectedTaskIdsToAppellantSubstitutionTable < Caseflow::Migration
  def change
    add_column :appellant_substitutions, :claimant_type, :string, null: false,
      comment: "Claimant type of substitute; needed to create Claimant record"

    add_column :appellant_substitutions, :selected_tasks_ids, :string, array: true, null: false, default: [],
      comment: "User-selected task ids from source appeal"

    add_column :appellant_substitutions, :task_params, :jsonb, null: false, default: '{}',
      comment: "JSON hash to hold parameters for new tasks, such as an EvidenceSubmissionWindowTask's end-hold date, with keys from selected_tasks_ids"
  end
end
