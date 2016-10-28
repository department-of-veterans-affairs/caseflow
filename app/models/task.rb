class Task < ActiveRecord::Base
  def assign!(user_id)
    update_attributes!(user_id: user_id, assigned_at: Time.now.utc)
  end

  def start!
    update_attributes!(started_at: Time.now.utc)
  end

  def complete!(status)
    update_attributes!(completed_at: Time.now.utc, status: status)
  end
end