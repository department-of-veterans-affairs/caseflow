# frozen_string_literal: true

class TranscriptionContractor < ApplicationRecord
  validates :name, presence: true
  validates :directory, presence: true

  def self.all_contractors
    all
  end
end
