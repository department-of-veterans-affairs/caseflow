class CreateBoardGrantEffectuations < ActiveRecord::Migration[5.1]
  def change
    create_table :board_grant_effectuations do |t|
      t.belongs_to :appeal, null: false
      t.belongs_to :granted_decision_issue, null: false
      t.belongs_to :end_product_establishment
      t.string     :contention_reference_id
      t.belongs_to :decision_document
    end
  end
end
