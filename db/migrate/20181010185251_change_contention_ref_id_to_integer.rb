class ChangeContentionRefIdToInteger < ActiveRecord::Migration[5.1]
  def up
    execute "alter table request_issues alter column contention_reference_id type integer using (contention_reference_id::integer)"
    safety_assured { add_index(:request_issues, :contention_reference_id, unique: true) }
  end

  def down
    execute "alter table request_issues alter column contention_reference_id type varchar using (contention_reference_id::varchar)"
    remove_index(:request_issues, :contention_reference_id)
  end
end
