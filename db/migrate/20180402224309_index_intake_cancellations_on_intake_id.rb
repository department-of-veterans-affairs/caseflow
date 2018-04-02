class IndexIntakeCancellationsOnIntakeId < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    add_index :intake_cancellations, :intake_id, algorithm: :concurrently
  end
end
