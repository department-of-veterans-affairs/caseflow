class AddAmaOnlyToOrganization < Caseflow::Migration
  def change
    add_column :organizations, :ama_only_push, :boolean, :default => false
    add_column :organizations, :ama_only_request, :boolean, :default => false
  end
end
