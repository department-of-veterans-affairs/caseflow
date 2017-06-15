class Fakes::CaseAssignmentRepository < CaseAssignmentRepository
  # rubocop:disable MethodLength
  def self.load_from_vacols(_user_id)
    [
      Appeal.create_appeal_with_extra_fields({
        vacols_id: "reader_id1",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: "2013-05-31 00:00:00 UTC".to_datetime,
        signed_date: nil,
        veteran_id: "1234",
        veteran_name: "Simple Case"
      }),
      Appeal.create_appeal_with_extra_fields({
        vacols_id: "reader_id2",
        date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
        date_received: nil,
        signed_date: nil,
        veteran_id: "5",
        veteran_name: "Large Case"
      }),
      Appeal.create_appeal_with_extra_fields({
        vacols_id: "reader_id3",
        date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
        date_received: "2013-04-29 00:00:00 UTC".to_datetime,
        signed_date: nil,
        veteran_id: "6",
        veteran_name: "Redacted Document Case"
      })
    ]
  end
  # rubocop:enable MethodLength
end
