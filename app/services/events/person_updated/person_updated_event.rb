# frozen_string_literal: true

class Events::PersonUpdated::PersonUpdatedEvent
  class << self
    def header_attribute_map
      {
        "X-VA-DOB" => "date_of_birth",
        "X-VA-DOD" => "date_of_death",
        "X-VA-Email-Address" => "email_address",
        "X-VA-File-Number" => "file_number",
        "X-VA-First-Name" => "first_name",
        "X-VA-Last-Name" => "last_name",
        "X-VA-Middle-Name" => "middle_name",
        "X-VA-Name-Suffix" => "name_suffix",
        "X-VA-SSN" => "ssn"
      }
    end

    # This method reads the drc_example.json file for our load_example method
    def example_response
      File.read(
        Rails.root.join(
          "app",
          "services",
          "events",
          "person_updated",
          "person_updated_example.json"
        )
      )
    end
  end
end
