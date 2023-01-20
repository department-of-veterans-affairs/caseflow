# frozen_string_literal: true

class MembershipRequest < ApplicationRecord
  belongs_to :user
  belongs_to :organization

  validates :status, presence: true

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }
end
