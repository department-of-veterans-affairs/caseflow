class AddRequestIdIndexToVersions < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    # Versions table has millions of rows. Make sure migration doesn't fail by timing out.
    transaction_time_out = 10 * 60 * 1000
    ActiveRecord::Base.connection.execute "SET LOCAL statement_timeout = #{transaction_time_out}"

    add_index :versions, :request_id, algorithm: :concurrently
  end
end
