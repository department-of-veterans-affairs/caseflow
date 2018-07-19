class Organization < ApplicationRecord
  has_many :tasks, as: :assigned_to
end