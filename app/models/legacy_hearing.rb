class LegacyHearing < ApplicationRecord
  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :user # the judge
end
