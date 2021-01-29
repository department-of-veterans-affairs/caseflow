class AddVeteranDateOfDeath < ActiveRecord::Migration[5.2]
  def change
    add_column :veterans, :date_of_death, :date, comment: "Date of Death reported by BGS, cached locally"
  end
end
