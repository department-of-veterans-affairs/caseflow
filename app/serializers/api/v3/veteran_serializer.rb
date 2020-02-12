# frozen_string_literal: true

class Api::V3::VeteranSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  self.record_type = "Veteran"

  attributes :first_name, :middle_name, :last_name, :name_suffix, :file_number, :ssn, :participant_id
end
