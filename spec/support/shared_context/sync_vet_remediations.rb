# frozen_string_literal: true

shared_context "sync_vet_remediations" do
  # rubocop:disable Layout/HashAlignment
  let(:person_remediation_event_record) do
    {
      "id" => 4296,
      "event_id" => 1540,
      "created_at" => DateTime.new(2022, 1, 2),
      "updated_at" => DateTime.new(2022, 1, 1),
      "evented_record_type" => "Person",
      "evented_record_id" => 5854,
      "info" =>
        { "before_data" =>
          { "id" => 5854,
          "participant_id" => "601486438",
          "date_of_birth" => "Thu, 01 Jan 1970",
          "created_at" => "Wed, 30 Oct 2024 17:32:46.642838000 UTC +00:00",
          "updated_at" => "Wed, 30 Oct 2024 17:32:47.112988000 UTC +00:00",
          "first_name" => "HEIDI",
          "last_name" => "HERMAN",
          "middle_name" => nil,
          "name_suffix" => nil,
          "email_address" => nil,
          "ssn" => "683378050" },
        "record_data"=>
          { "id" => 5854,
          "participant_id" => "601486438",
          "date_of_birth" => "Thu, 01 Jan 1970",
          "created_at" => "Wed, 30 Oct 2024 17:32:46.642838000 UTC +00:00",
          "updated_at" => "Wed, 30 Oct 2024 17:32:47.112988000 UTC +00:00",
          "first_name" => "HEIDI",
          "last_name" => "HERMAN",
          "middle_name" => nil,
          "name_suffix" => nil,
          "email_address" => nil,
          "ssn" => "683378050" },
        "update_type" => "U" }
    }
  end

  let(:veteran_remediation_event_record) do
    {
      "id" => 4296,
      "event_id" => 1540,
      "created_at" => DateTime.new(2022, 1, 2),
      "updated_at" => DateTime.new(2022, 1, 1),
      "evented_record_type" => "Veteran",
      "evented_record_id" => 5854,
      "info" =>
        { "before_data" =>
          { "id" => 8346,
          "file_number" => "683378050",
          "participant_id" => "601486438",
          "first_name" => "HEIDI",
          "last_name" => "HERMAN",
          "middle_name" => nil,
          "name_suffix" => nil,
          "closest_regional_office" => nil,
          "ssn" => "683378050",
          "created_at" => "Wed, 30 Oct 2024 17:32:29.119027000 UTC +00:00",
          "updated_at" => "Wed, 30 Oct 2024 18:48:34.844740000 UTC +00:00",
          "date_of_death" => nil,
          "date_of_death_reported_at" => nil,
          "bgs_last_synced_at" => "Wed, 30 Oct 2024 18:48:34.844336000 UTC +00:00"},
        "record_data" =>
          { "id" => 8346,
          "file_number" => "683378050",
          "participant_id" => "601486438",
          "first_name" => "HEIDI",
          "last_name" => "HERMAN",
          "middle_name" => nil,
          "name_suffix" => nil,
          "closest_regional_office" => nil,
          "ssn" => "683378050",
          "created_at" => "Wed, 30 Oct 2024 17:32:29.119027000 UTC +00:00",
          "updated_at" => "Wed, 30 Oct 2024 18:48:34.844740000 UTC +00:00",
          "date_of_death" => nil,
          "date_of_death_reported_at" => nil,
          "bgs_last_synced_at" => "Wed, 30 Oct 2024 18:48:34.844336000 UTC +00:00" },
        "update_type" => "U" }
    }
  end
end
