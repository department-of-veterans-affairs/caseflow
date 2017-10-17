class Generators::Issue
  extend Generators::Base

  class << self
    def default_attrs
      {
        disposition: "Allowed",
        description: [
          "15 - Service connection",
          "03 - All Others",
          "5252 - Thigh, limitation of flexion of"
        ],
        levels: ["All Others", "Thigh, limitation of flexion of"],
        program_description: "02 - Compensation",
        program: :compensation,
        type: { name: :service_connection, label: "Service Connection" },
        category: :knee,
        note: "low back condition",
        vacols_sequence_id: 1
      }
    end

    def build(attrs = {})
      attrs.delete(:vacols_id)
      ::Issue.new(default_attrs.merge(attrs))
    end
  end
end
