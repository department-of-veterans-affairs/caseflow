class ClaimsFolderSearch < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :user
end
