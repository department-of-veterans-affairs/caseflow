class AddAcceptsPriorityPushedCasesToEtlOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :accepts_priority_pushed_cases, :boolean, comment: "Whether a JudgeTeam currently accepts distribution of automatically pushed priority cases"
  end
end
