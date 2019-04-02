class AddUuidIndices < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
    add_index :appeals, :uuid, algorithm: :concurrently
    add_index :hearings, :uuid, algorithm: :concurrently
    add_index :higher_level_reviews, :uuid, algorithm: :concurrently
    add_index :supplemental_claims, :uuid, algorithm: :concurrently
  end
end
