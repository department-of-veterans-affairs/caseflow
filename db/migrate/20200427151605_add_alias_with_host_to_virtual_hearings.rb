class AddAliasWithHostToVirtualHearings < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_column :virtual_hearings, :alias_with_host, :string, comment: "Alias for conference in pexip with client_host"
    add_index :virtual_hearings, :alias_with_host, algorithm: :concurrently
  end
end
