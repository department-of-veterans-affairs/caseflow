# frozen_string_literal: true

class TranscriptionContractor < ApplicationRecord
  validates :name, presence: true
  validates :directory, presence: true

  def self.get_directory_by_name(name)
    contractor = find_by(name: name)

    if contractor.nil?
      return nil
    end

    contractor.directory
  end
end
