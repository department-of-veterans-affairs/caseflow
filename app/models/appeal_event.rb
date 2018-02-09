class AppealEvent
  include ActiveModel::Model

  V1_EVENT_TYPE_FOR_DISPOSITIONS = {
    bva_final_decision: [
      "Allowed",
      "Denied",
      "Vacated",
      "Dismissed, Death",
      "Dismissed, Other"
    ],
    bva_remand: [
      "Remanded",
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
      "Advance Withdrawn Death of Veteran",
      "Advance Withdrawn by Appellant/Rep",
      "Advance Failure to Respond",
      "Remand Failure to Respond",
      "RAMP Opt-in"
    ],
    merged: [
      "Merged Appeal"
    ],
    other: [
      "Designation of Record",
      "Reconsideration by Letter"
    ]
  }.freeze

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
    death: [
      "Dismissed, Death",
      "Advance Withdrawn Death of Veteran"
    ],
    merged: [
      "Merged Appeal"
    ],
    record_designation: [
      "Designation of Record"
    ],
    reconsideration: [
      "Reconsideration by Letter"
    ],
    vacated: [
      "Vacated"
    ],
    other_close: [
      "Dismissed, Other"
    ]
  }.freeze

  V1_EVENT_TYPE_FOR_HEARING_DISPOSITIONS = {
    hearing_held: :held,
    hearing_cancelled: :cancelled,
    hearing_no_show: :no_show
  }.freeze

  EVENT_TYPE_FOR_HEARING_DISPOSITIONS = {
    hearing_held: :held,
    hearing_no_show: :no_show
  }.freeze

  EVENT_TYPE_FOR_ISSUE_DISPOSITIONS = {
    field_grant: [
      "Benefits Granted by AOJ",
      "Advance Allowed in Field"
    ]
  }.freeze

  attr_accessor :type, :date

  def to_hash
    { type: type, date: date.to_date }
  end

  def v1_disposition=(disposition)
    self.type = v1_type_from_disposition(disposition)
  end

  def disposition=(disposition)
    self.type = type_from_disposition(disposition)
  end

  def issue_disposition=(disposition)
    self.type = type_from_issue_disposition(disposition)
  end

  def v1_hearing=(hearing)
    self.type = V1_EVENT_TYPE_FOR_HEARING_DISPOSITIONS.key(hearing.disposition)
    self.date = hearing.date
  end

  def hearing=(hearing)
    self.type = EVENT_TYPE_FOR_HEARING_DISPOSITIONS.key(hearing.disposition)
    self.date = hearing.date
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

  def v1_type_from_disposition(disposition)
    V1_EVENT_TYPE_FOR_DISPOSITIONS.keys.find do |type|
      V1_EVENT_TYPE_FOR_DISPOSITIONS[type].include?(disposition)
    end
  end

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
