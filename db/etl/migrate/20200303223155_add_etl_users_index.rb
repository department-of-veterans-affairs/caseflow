class AddEtlUsersIndex < Caseflow::Migration
  def change
    add_safe_index :users, [:user_id]
  end
end
