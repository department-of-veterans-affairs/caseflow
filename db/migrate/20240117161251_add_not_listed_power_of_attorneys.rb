class AddNotListedPowerOfAttorneys < Caseflow::Migration
  disable_ddl_transaction!

  def change
    create_table :not_listed_power_of_attorneys do |t|
      t.timestamps
    end

    add_reference :unrecognized_appellants, :not_listed_power_of_attorney, foreign_key: true, index: false
  end
end
