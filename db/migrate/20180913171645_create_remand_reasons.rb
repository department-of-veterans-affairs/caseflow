class CreateRemandReasons < ActiveRecord::Migration[5.1]
  def change
    create_table :remand_reasons do |t|
      t.belongs_to :request_issue
      t.boolean :post_aoj
      t.string :code
      t.timestamps null: false
    end
  end
end
