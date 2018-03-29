class AppealView < ApplicationRecord
  belongs_to :appeal
  belongs_to :user
end
