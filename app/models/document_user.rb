class DocumentUser < ActiveRecord::Base
  belongs_to :document
  belongs_to :user
end
