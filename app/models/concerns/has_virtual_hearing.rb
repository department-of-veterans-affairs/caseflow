# frozen_string_literal: true

module HasVirtualHearing
  extend ActiveSupport::Concern

  included do
    has_one :virtual_hearing, -> { order(id: :desc) }, as: :hearing
  end

  def virtual?
    [
      VirtualHearing.statuses[:pending],
      VirtualHearing.statuses[:active]
    ].include? virtual_hearing&.status
  end
end
