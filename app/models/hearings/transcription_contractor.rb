# frozen_string_literal: true

class TranscriptionContractor < ApplicationRecord
  validates :name, presence: true
  validates :directory, presence: true
end
