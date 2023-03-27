# frozen_string_literal: true

class ConferenceLinkSerializer
  include FastJsonapi::ObjectSerializer
  attribute :host_pin
  attribute :host_link, &:host_link
  attribute :alias, &:alias_with_host
  attribute :guest_pin, &:guest_pin_long
  attribute :guest_link, &:guest_hearing_link
end
