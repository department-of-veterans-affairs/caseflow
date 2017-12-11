class CreateRampRefilings < ActiveRecord::Migration
  safety_assured

  def change
    create_table :ramp_refilings do |t|
      t.string     :veteran_file_number, null: false
      t.belongs_to :ramp_election
      t.string     :option_selected
      t.date       :receipt_date
      t.string     :end_product_reference_id
    end

    add_index(:ramp_refilings, :veteran_file_number)
  end
end
