class AddActiveToUsers < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :active, :boolean, default: true, comment: "Whether or not a user is an active user of caseflow"
  end
end
