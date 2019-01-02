class HearingView < ApplicationRecord
  belongs_to :hearing, class_name: "LegacyHearing"
  belongs_to :user
end
