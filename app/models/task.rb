class Task < ActiveRecord::Base
  def assign!(user_id)
    update_attributes!(user_id: user_id)
  end
end