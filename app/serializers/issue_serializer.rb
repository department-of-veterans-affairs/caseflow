# frozen_string_literal: true

class IssueSerializer
  include JSONAPI::Serializer
  set_key_transform :camel_lower

  attribute :active, &:api_status_active?
  attribute :last_action, &:api_status_last_action
  attribute :date, &:api_status_last_action_date
  attribute :description, &:api_status_description
  attribute :diagnostic_code, &:diagnostic_code
end
