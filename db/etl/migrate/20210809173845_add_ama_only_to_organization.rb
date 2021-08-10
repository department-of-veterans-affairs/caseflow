class AddAmaOnlyToOrganization < Caseflow::Migration
  def change
    add_column :organizations, :ama_only, :boolean, :default => false
  end
end
