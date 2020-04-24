# frozen_string_literal: true

module HasVirtualHearing
  extend ActiveSupport::Concern

  included do
    has_one :virtual_hearing, -> { order(id: :desc) }, as: :hearing

    has_many :email_events, class_name: "SentHearingEmailEvent"
  end

  def virtual?
    [
      :pending,
      :active
    ].include? virtual_hearing&.status
  end

  def was_virtual?
    !virtual_hearing.nil? && !virtual?
  end
end
