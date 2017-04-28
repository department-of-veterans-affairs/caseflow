class Tag < ActiveRecord::Base
  has_and_belongs_to_many :documents

  validates :text, presence: true
end
