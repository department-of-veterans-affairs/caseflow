class UpdateAppealStateUpdatedAtColumn < ActiveRecord::Migration[5.2]
  def change
    t.timestamp  :created_at, comment: "Timestamp of when Noticiation was Created"
    t.timestamp  :updated_at, 
  end
end
