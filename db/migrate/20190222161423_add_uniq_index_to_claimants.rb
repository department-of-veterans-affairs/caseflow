class AddUniqIndexToClaimants < ActiveRecord::Migration[5.1]
  disable_ddl_transaction!

  def change
  	add_index :claimants, [:participant_id, :review_request_id, :review_request_type], name: "uniq_index_on_participant_id_review_request", unique: true, algorithm: :concurrently
  end
end

