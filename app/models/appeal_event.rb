class AppealEvent
  include ActiveModel::Model

  EVENT_TYPE_FOR_DISPOSITIONS = {
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
      "Reconsideration by Letter",
    ]
  }.freeze

  EVENT_TYPE_FOR_HEARING_DISPOSITIONS = {
    hearing_held: :held,
    hearing_cancelled: :cancelled,
    hearing_no_show: :no_show
  }.freeze

  attr_accessor :type, :date

  def to_hash
    { type: type, date: date.to_date }
  end

  def disposition=(disposition)
    self.type = type_from_disposition(disposition)
  end

  def hearing=(hearing)
    self.type = EVENT_TYPE_FOR_HEARING_DISPOSITIONS.key(hearing.disposition)
    self.date = hearing.date
  end

  def valid?
    type && date
  end

  private

  def type_from_disposition(disposition)
    EVENT_TYPE_FOR_DISPOSITIONS.keys.find do |type|
      EVENT_TYPE_FOR_DISPOSITIONS[type].include?(disposition)
    end
  end
end
