class AppealEvent
  include ActiveModel::Model

  # TODO: Confirm this list with Chris, do we have all dispositions accounted for?
  # rubocop:disable Style/WordArray
  DISPOSITIONS_BY_EVENT_TYPE = {
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
      "Remand Failure to Respond"
    ],
    merged: [
      "Merged Appeal"
    ],
    other: [
      "Designation of Record",
      "Reconsideration by Letter"
    ]
  }.freeze
  # rubocop:enable Style/WordArray

  attr_accessor :type, :date

  def to_hash
    { type: type, date: date.to_date }
  end

  def disposition=(disposition)
    self.type = type_from_disposition(disposition)
  end

  def valid?
    type && date
  end

  private

  def type_from_disposition(disposition)
    DISPOSITIONS_BY_EVENT_TYPE.keys.find do |type|
      DISPOSITIONS_BY_EVENT_TYPE[type].include?(disposition)
    end
  end
end
