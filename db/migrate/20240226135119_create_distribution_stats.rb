class CreateDistributionStats < Caseflow::Migration
  def change
    create_table :distribution_stats, comment: "A database table to store a snapshot of variables used during a case distribution event" do |t|
      t.references :distribution, foreign_key: true, comment: "ID of the associated Distribution", index: true
      t.json :statistics, null: true, comment:"Indicates a snapshot of variables used during the distribution"
      t.json :levers, null: true, comment:"Indicates a snapshot of lever values and is_toggle_active for a distribution"
      t.timestamps
    end
  end
end
