# frozen_string_literal: true

class StatusSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :type, &:fetch_status
  attribute :details, &:fetch_details_for_status
end
