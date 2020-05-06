class AddAliasWithHostToVirtualHearings < ActiveRecord::Migration[5.2]
  def change
    add_column :virtual_hearings, :alias_with_host, :string, comment: "Alias for conference in pexip with client_host"
  end
end
