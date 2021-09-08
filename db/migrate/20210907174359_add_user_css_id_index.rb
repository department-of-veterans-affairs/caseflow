class AddUserCssIdIndex < Caseflow::Migration
  def change
    add_index(:users, :css_id, unique: true, algorithm: :concurrently)
  end
end
