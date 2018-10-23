class DispatchLegacyTask < LegacyTask
  def self.from_vacols(record, appeal, user)
    new(
      id: record.vacols_id,
      appeal_id: appeal.id,
      assigned_to: user,
      appeal: appeal
    )
  end
end