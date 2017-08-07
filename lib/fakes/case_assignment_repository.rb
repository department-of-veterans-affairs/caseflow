class Fakes::CaseAssignmentRepository < CaseAssignmentRepository
  cattr_accessor :appeal_records

  class << self
    # rubocop:disable Metrics/MethodLength
    def default_records
      [
        Generators::Appeal.build(
          type: "Court Remand",
          cavc: true,
          vacols_id: "reader_id1",
          date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
          date_received: "2013-05-31 00:00:00 UTC".to_datetime,
          signed_date: nil,
          vbms_id: "1234",
          veteran_first_name: "Simple",
          veteran_middle_initial: "A",
          veteran_last_name: "Case",
          docket_number: "13 11-265",
          regional_office_key: "RO13",
          issues: [
            { disposition: :remanded,
              program: :compensation,
              vacols_sequence_id: 1,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] },
            { disposition: :remanded,
              program: :compensation,
              vacols_sequence_id: 2,
              type: { name: :increased_rating, label: "Increased Rating" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] },
            { disposition: :remanded,
              program: :compensation,
              vacols_sequence_id: 3,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] }
          ]),
        Generators::Appeal.build(
          type: "Remand",
          cavc: false,
          vacols_id: "reader_id2",
          date_assigned: "2013-05-17 00:00:00 UTC".to_datetime,
          date_received: nil,
          signed_date: nil,
          vbms_id: "5",
          veteran_first_name: "Large",
          veteran_middle_initial: "B",
          veteran_last_name: "Case",
          docket_number: "13 11-265",
          regional_office_key: "RO13",
          issues: [
            { disposition: :remanded,
              program: :compensation,
              vacols_sequence_id: 1,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] },
            { disposition: :remanded,
              program: :compensation,
              vacols_sequence_id: 2,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] },
            { disposition: :remanded,
              program: :compensation,
              vacols_sequence_id: 3,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] }
          ]),
        Generators::Appeal.build(
          type: "Remand",
          cavc: false,
          vacols_id: "reader_id3",
          date_assigned: "2013-04-23 00:00:00 UTC".to_datetime,
          date_received: "2013-04-29 00:00:00 UTC".to_datetime,
          signed_date: nil,
          vbms_id: "6",
          veteran_first_name: "Redacted",
          veteran_middle_initial: "C",
          veteran_last_name: "Case",
          docket_number: "13 11-265",
          regional_office_key: "RO13",
          issues: [
            { disposition: :remanded,
              vacols_sequence_id: 1,
              program: :compensation,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] },
            { disposition: :remanded,
              vacols_sequence_id: 2,
              program: :compensation,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] },
            { disposition: :remanded,
              vacols_sequence_id: 3,
              program: :compensation,
              type: { name: :service_connection, label: "Service Connection" }, category: :knee, levels: [
                "Lumbosacral",
                "All Others",
                "Thigh, limitation of flexion of"
              ] }
          ])
      ]
    end
    # rubocop:enable Metrics/MethodLength

    def load_from_vacols(_css_id)
      appeal_records || default_records
    end
  end
end
