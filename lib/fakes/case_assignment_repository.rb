class Fakes::CaseAssignmentRepository < CaseAssignmentRepository
  # rubocop:disable MethodLength
  def self.load_from_vacols(_user_id)
    [
      {
        vacols_id: "2743803",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: "2013-05-31 00:00:00 UTC".to_datetime,
        signed_date: nil
      },
      {
        vacols_id: "2747917",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: nil,
        signed_date: nil
      },
      {
        vacols_id: "2710024",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        signed_date: nil
      },
      {
        vacols_id: "2417093",
        date_assigned: "2013-05-29 00:00:00 UTC".to_datetime,
        date_received: "2013-06-03 00:00:00 UTC".to_datetime,
        signed_date: nil
      },
      {
        vacols_id: "2725685",
        date_assigned: "2013-05-31 00:00:00 UTC".to_datetime,
        date_received: nil,
        signed_date: nil
      }
    ]
  end
  # rubocop:enable MethodLength
end
