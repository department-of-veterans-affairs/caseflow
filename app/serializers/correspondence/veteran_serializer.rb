# frozen_string_literal: true

class Correspondence::VeteranSerializer
  include FastJsonapi::ObjectSerializer
  set_key_transform :camel_lower

  attributes :id, :first_name, :last_name, :file_number

  attribute :full_name do |object|
    object.name.to_s
  end
end
