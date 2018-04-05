class CreateHearings < ActiveRecord::Migration[5.1]
  def change
    create_table :hearings do |t|
      # maps to the judge conducting the hearing
      t.belongs_to :user
      t.belongs_to :appeal

      # maps to unique ID in HEARSCHED table
      t.string :vacols_id, null: false
    end
  end
end
