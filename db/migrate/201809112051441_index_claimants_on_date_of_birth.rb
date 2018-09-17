class IndexClaimantsOnDateOfBirth < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :claimants, :date_of_birth, algorithm: :concurrently
  end
end
