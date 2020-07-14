class AddAutomatedPriorityCaseDistributionToEtlOrganization < ActiveRecord::Migration[5.1]
  def change
    add_column :organizations, :automated_priority_case_distribution, :boolean, comment: "Whether a JudgeTeam is currently available for automatically pushed priority cases"
  end
end
