class ClaimsFolderSearch < ApplicationRecord
  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :user
end
