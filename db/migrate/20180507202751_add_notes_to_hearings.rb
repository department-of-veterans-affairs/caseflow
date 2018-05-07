class AddNotesToHearings < ActiveRecord::Migration[5.1]
  def change
    add_column :hearings, :notes, :string
  end
end
