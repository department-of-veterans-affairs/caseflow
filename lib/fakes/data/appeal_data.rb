# rubocop:disable Metrics/ModuleLength
module Fakes::Data::AppealData
  # rubocop:disable Metrics/MethodLength
  def self.default_records
    [
      Generators::Appeal.build(
        type: "Court Remand",
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
            vacols_sequence_id: 1,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          }
        ]),
      Generators::Appeal.build(
        type: "Remand",
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
            vacols_sequence_id: 1,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          }
        ]),
      Generators::Appeal.build(
        type: "Remand",
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
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          },
          { disposition: :remanded,
            vacols_sequence_id: 2,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          },
          { disposition: :remanded,
            vacols_sequence_id: 3,
            codes: %w(02 15 03 5252),
            labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
          }
        ])
    ]
  end
  # rubocop:enable Metrics/MethodLength
end
# rubocop:enable Metrics/ModuleLength
