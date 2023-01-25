# frozen_string_literal: true

class MembershipRequest < ApplicationRecord
  belongs_to :organization

  validates :status, :organization, presence: true

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }, default: :assigned
end
