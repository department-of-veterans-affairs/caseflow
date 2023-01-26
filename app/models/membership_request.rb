# frozen_string_literal: true

class MembershipRequest < ApplicationRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User", foreign_key: :requested_by_id
  belongs_to :decider, class_name: "User", foreign_key: :decided_by_id, optional: true

  validates :status, :organization, :requested_by_id, presence: true

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }
end
