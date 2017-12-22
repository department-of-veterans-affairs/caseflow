class HearingView < ActiveRecord::Base
  belongs_to :hearing
  belongs_to :user
end
