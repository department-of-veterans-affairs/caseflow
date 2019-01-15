class HearingView < ApplicationRecord
  belongs_to :hearing, polymorphic: true
  belongs_to :user
end
