class CreateTaskBusinessPayload < ActiveRecord::Migration[5.1]
  safety_assured

  def change
    create_table :task_business_payloads do |t|
      t.belongs_to :task, null: false
      t.string :description, null: false
      t.json :values, default: {}, null: false
    end
  end
end