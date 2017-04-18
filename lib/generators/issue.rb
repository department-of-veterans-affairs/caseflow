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
        program: "02 - Compensation",
        new_material: false
      }
    end

    def build(attrs = {})
      Issue.new(default_attrs.merge(attrs))
    end
  end
end
