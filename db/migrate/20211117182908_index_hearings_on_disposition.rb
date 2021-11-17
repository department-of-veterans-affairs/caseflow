class IndexHearingsOnDisposition < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index :hearings, :disposition, algorithm: :concurrently
  end
end
