class Tag < ActiveRecord::Base
  belongs_to :document
  
  validates :text, presence: true
  validates :document, presence: true
end
