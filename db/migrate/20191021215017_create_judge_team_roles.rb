class CreateJudgeTeamRoles < ActiveRecord::Migration[5.1]
  def change
    create_table :judge_team_roles, comment: "Defines roles for individual members of judge teams" do |t|
      t.string :type
      t.column :organizations_user_id, :integer
      t.index :organizations_user_id, unique: true
      t.timestamps
    end
  end
end
