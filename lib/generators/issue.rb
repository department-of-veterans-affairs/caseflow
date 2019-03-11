# frozen_string_literal: true

class Generators::Issue
  extend Generators::Base

  class << self
    def default_attrs
      {
        disposition: "Allowed",
        disposition_id: "1",
        close_date: 7.days.ago,
        codes: %w[02 15 03 5252],
        labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"],
        note: "low back condition",
        vacols_sequence_id: 1,
        id: generate_external_id
      }
    end

    def templates
      {
        compensation: {
          codes: %w[02 15 03 5252],
          labels: ["Compensation", "Service connection", "All Others", "Thigh, limitation of flexion of"]
        },
        education: {
          codes: %w[03 15 03 5252],
          labels: ["Education", "Service connection", "All Others", "Thigh, limitation of flexion of"]
        }
      }
    end

    def build(attrs = {})
      template_attrs = templates[attrs.delete(:template)] || {}
      ::Issue.new(default_attrs.merge(template_attrs).merge(attrs))
    end
  end
end
