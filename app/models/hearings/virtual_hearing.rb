# frozen_string_literal: true

class VirtualHearing < ApplicationRecord
  alias_attribute :alias_name, :alias

  belongs_to :hearing, polymorphic: true
  belongs_to :created_by, class_name: "User"

  before_create :assign_created_by_user

  enum status: {
    # Initial status for a virtual hearing. Indicates the Pexip conference
    # does not exist yet
    pending: "pending",

    # Indicates that the Pexip conference was created
    active: "active",

    # Indicates that the hearing was cancelled, and the Pexip conference needs
    # to be cleaned up
    cancelled: "cancelled"
  }

  scope :eligible_for_deletion,
        -> { where(conference_deleted: false, status: [:active, :cancelled]) }

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end
end
