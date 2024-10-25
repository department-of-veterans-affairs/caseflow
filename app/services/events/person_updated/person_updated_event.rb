# frozen_string_literal: true

class Events::PersonUpdated::PersonUpdatedEvent
  class << self
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
