class CreateDistributedCases < ActiveRecord::Migration[5.1]
  def change
    create_table :distributed_cases do |t|
      t.integer :distribution_id
      t.string :case_id
      t.string :docket
      t.boolean :priority
      t.boolean :genpop
      t.string :genpop_query
      t.integer :docket_index
      t.datetime :ready_at
    end
  end
end
