# frozen_string_literal: true

module HasVirtualHearing
  extend ActiveSupport::Concern

  included do
    has_one :virtual_hearing, -> { order(id: :desc) }, as: :hearing
  end

  # NOTE: A hearing is virtual unless the hearing type was switched back to original
  # indicated by status `cancelled`
  def virtual?
    [
      :pending,
      :active,
      :closed
    ].include? virtual_hearing&.status
  end

  def was_virtual?
    !virtual_hearing.nil? && !virtual?
  end

  def hearing_request_type
    return "Virtual" if virtual?

    readable_request_type
  end
end
