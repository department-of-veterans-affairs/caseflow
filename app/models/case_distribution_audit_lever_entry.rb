# frozen_string_literal: true

class CaseDistributionAuditLeverEntry < ApplicationRecord
  belongs_to :user
  belongs_to :case_distribution_lever

  scope :past_year, -> { where(created_at: (Time.zone.now - 1.year)...Time.zone.now) }

  def self.lever_history
    history = includes(:user, :case_distribution_lever).past_year
    CaseDistributionAuditLeverEntrySerializer.new(history).serializable_hash[:data].map { |entry| entry[:attributes] }
  end
end
