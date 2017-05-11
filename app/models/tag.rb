class Tag < ActiveRecord::Base
  has_many :documents_tags
  has_many :documents, through: :documents_tags

  validates :text, presence: true
end
