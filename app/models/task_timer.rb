class TaskTimer < ApplicationRecord
  belongs_to :task
  include Asyncable
end
