class AddRequestIdToVersions < ActiveRecord::Migration[5.1]
  def change
    add_column :versions, :request_id, :uuid, comment: "The unique id of the request that caused this change"
  end
end
