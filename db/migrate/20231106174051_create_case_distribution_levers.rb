class CreateCaseDistributionLevers < Caseflow::Migration
  def change
    create_table :case_distribution_levers, comment:"A generalized table for Case Distribution lever records within caseflow" do |t|
      t.string :item, null: false, comment:"Is unique value to identify the Case Distribution lever"
      t.string :title, null: false, comment:"Indicates the Lever title"
      t.text :description, null: true, comment:"Indicates the description of the Lever"
      t.string :data_type, null: false, comment:"Indicates which type of record either BOOLEAN/RADIO/COMBO"
      t.string :value, null: false, comment:"Indicates the value based in the data type wither string/number"
      t.string :unit, null: true, comment:"Indicates the type of data like Cases or Days"
      t.boolean :is_active, null: false, comment:"Indicates the active lever"
      t.boolean :is_disabled, null: false, comment:"Used to diabled the row"
      t.integer :min_value, null: true, comment:"Set min value for the input"
      t.integer :max_value, null: true, comment:"Set max value for the input"
      t.json :algorithms_used, null: true, comment:"Indicates the algorithms used"
      t.json :options, null: true, comment:"Indicates the options which contain json formatted data"
      t.json :control_group, null: true, comment:"Indicates the group which contain json formatted data that controls the Case Distribution Levers"
      t.timestamps
    end
  end
end
