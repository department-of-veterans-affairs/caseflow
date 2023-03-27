# frozen_string_literal: true

class ConferenceLinkSerializer
  include FastJsonapi::ObjectSerializer
  attribute :host_pin
  attribute :host_link, &:host_link
  attribute :alias
end
