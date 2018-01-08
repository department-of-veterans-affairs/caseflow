class Generators::Issue
  extend Generators::Base

  class << self
    def default_attrs
      {
        disposition: "Allowed",
        close_date: 7.days.ago,
        codes: %w[02 15 03 5252],
        labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"],
        note: "low back condition",
        vacols_sequence_id: 1,
        id: generate_external_id
      }
    end

    def build(attrs = {})
      ::Issue.new(default_attrs.merge(attrs))
    end
  end
end
