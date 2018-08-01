class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to

  def user_has_access?(_user)
    false
  end
end
