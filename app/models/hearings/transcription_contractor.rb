# frozen_string_literal: true

class TranscriptionContractor < ApplicationRecord
  acts_as_paranoid

  has_many :transcriptions

  validates :current_goal, presence: true
  validates :directory, presence: true
  validates :email, presence: true
  validates :inactive, inclusion: { in: [true, false] }
  validates :is_available_for_work, inclusion: { in: [true, false] }
  validates :name, presence: true
  validates :phone, presence: true
  validates :poc, presence: true

  before_update :assign_previous_goal

  def self.all_contractors
    all.order(:name)
  end

  private

  # auto assign the value of current goal to previous goal when current goal changes
  def assign_previous_goal
    self.previous_goal = current_goal_was
  end
end
