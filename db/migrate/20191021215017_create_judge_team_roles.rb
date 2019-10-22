class CreateJudgeTeamRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :judge_team_roles do |t|
      t.string :type
      t.column :organizations_user_id, :integer
      t.index :organizations_user_id, unique: true
      t.timestamps
    end
  end
end
