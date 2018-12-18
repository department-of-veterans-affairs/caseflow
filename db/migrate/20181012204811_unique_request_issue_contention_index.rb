class UniqueRequestIssueContentionIndex < ActiveRecord::Migration[5.1]
  safety_assured

  def up
    safety_assured do
      add_index(:request_issues, [:contention_reference_id, :removed_at], unique: true)
      remove_index(:request_issues, :contention_reference_id)
    end
  end

  def down
    safety_assured do
      remove_index(:request_issues, [:contention_reference_id, :removed_at])
      add_index(:request_issues, :contention_reference_id, unique: true)
    end
  end
end
