# frozen_string_literal: true

class ConferenceLinkSerializer
  include FastJsonapi::ObjectSerializer
  attribute :host_pin
  attribute :host_link, &:host_link
  attribute :alias, &:alias_with_host
  attribute :guest_pin, &:guest_pin
  attribute :guest_link, &:guest_link
  attribute :co_host_link, &:co_host_link
  attribute :type
  attribute :conference_provider
end
