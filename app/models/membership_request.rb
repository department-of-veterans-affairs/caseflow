# frozen_string_literal: true

class MembershipRequest < ApplicationRecord
  belongs_to :organization
  belongs_to :requestor, class_name: "User", foreign_key: :requested_by
  belongs_to :decisioner, class_name: "User", foreign_key: :closed_by, optional: true

  validates :organization, presence: true
  validates :requestor, presence: true

  enum status: {
    assigned: "assigned",
    approved: "approved",
    denied: "denied",
    cancelled: "cancelled"
  }
end
