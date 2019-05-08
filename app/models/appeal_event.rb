# frozen_string_literal: true

class AppealEvent
  include ActiveModel::Model

  EVENT_TYPE_FOR_DISPOSITIONS = {
    bva_decision: [
      "Allowed",
      "Remanded",
      "Denied",
      "Manlincon Remand"
    ],
    field_grant: [
      "Benefits Granted by AOJ",
      "Advance Allowed in Field"
    ],
    withdrawn: [
      "Withdrawn",
      "Motion to Vacate Withdrawn",
      "Withdrawn from Remand",
      "Recon Motion Withdrawn",
      "Advance Withdrawn by Appellant/Rep"
    ],
    ftr: [
      "Advance Failure to Respond",
      "Remand Failure to Respond"
    ],
    ramp: [
      "RAMP Opt-in"
    ],
    statutory_opt_in: [
      "AMA SOC/SSOC Opt-in"
    ],
    death: [
      "Dismissed, Death",
      "Advance Withdrawn Death of Veteran"
    ],
    merged: [
      "Merged Appeal"
    ],
    reconsideration: [
      "Reconsideration by Letter"
    ],
    vacated: [
      "Vacated"
    ],
    other_close: [
      "Dismissed, Withdrawn"
    ]
  }.freeze

  EVENT_TYPE_FOR_HEARING_DISPOSITIONS = {
    hearing_held: Constants.HEARING_DISPOSITION_TYPES.held,
    hearing_no_show: Constants.HEARING_DISPOSITION_TYPES.no_show
  }.freeze

  EVENT_TYPE_FOR_ISSUE_DISPOSITIONS = {
    field_grant: [
      :advance_allowed_in_field,
      :benefits_granted_by_aoj
    ]
  }.freeze

  attr_accessor :type, :date

  def to_hash
    { type: type, date: date.to_date }
  end

  def disposition=(disposition)
    self.type = type_from_disposition(disposition)
  end

  def issue_disposition=(disposition)
    self.type = type_from_issue_disposition(disposition)
  end

  def hearing=(hearing)
    self.type = EVENT_TYPE_FOR_HEARING_DISPOSITIONS.key(hearing.disposition)
    self.date = hearing.scheduled_for
  end

  def valid?
    type && date
  end

  # We override these methods in order to have AppealEvent behave as a value type.
  # Any two events with the same type and the same date are considered equal.
  # We'll use this property when uniquing lists of events.
  def ==(other)
    type == other.type && date == other.date
  end

  def eql?(other)
    self == other
  end

  def hash
    [type, date].hash
  end

  private

  def type_from_disposition(disposition)
    EVENT_TYPE_FOR_DISPOSITIONS.keys.find do |type|
      EVENT_TYPE_FOR_DISPOSITIONS[type].include?(disposition)
    end || :other_close
  end

  def type_from_issue_disposition(disposition)
    EVENT_TYPE_FOR_ISSUE_DISPOSITIONS.keys.find do |type|
      EVENT_TYPE_FOR_ISSUE_DISPOSITIONS[type].include?(disposition)
    end
  end
end
