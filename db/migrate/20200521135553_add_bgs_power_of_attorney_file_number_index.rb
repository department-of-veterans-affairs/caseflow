class AddBgsPowerOfAttorneyFileNumberIndex < Caseflow::Migration
  def change
    add_safe_index :bgs_power_of_attorneys, :file_number
  end
end
