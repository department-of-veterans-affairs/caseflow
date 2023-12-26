class CreateCaseDistributionAlgorithmLogs < Caseflow::Migration
  def change
    create_table :case_distribution_algorithm_logs, comment:"A generalized table for Case Distribution algorithm logs records within caseflow" do |t|
      t.string :script_name, comment:"Indicates the script name that was run"
      t.json :levers, comment:"Indicates the Levers information from the CaseDistributionLevers table"
      t.integer :starting_distribution_id, comment:"Indicates the starting distribution id"
      t.integer :ending_distribution_id, comment:"Indicates the ending distribution id"
      t.string :starting_case_id, comment:"Indicates the starting case id"
      t.string :ending_case_id, comment:"Indicates the ending case id"
      t.timestamps
    end
  end
end
