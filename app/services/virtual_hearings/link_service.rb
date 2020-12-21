# frozen_string_literal: true

require "digest"

##
# Service for generating new guest and host virtual hearings links
##
class VirtualHearings::LinkService
  class PINKeyMissingError < StandardError; end
  class PINMustBePresentError < StandardError; end
  class NameMustBePresentError < StandardError; end

  JUDGE_NAME = "Judge"
  GUEST_NAME = "Guest"

  def host_link
    link(host_pin, JUDGE_NAME)
  end

  def guest_link
    link(guest_pin, GUEST_NAME)
  end

  def host_pin
    pin_hash("#{pin_key}#{conference_id}")[0..6]
  end

  def guest_pin
    pin_hash("#{conference_id}#{pin_key}")[0..9]
  end

  private

  def link(pin, name)
    fail PINMustBePresentError if pin.blank?
    fail NameMustBePresentError if name.blank?

    "#{base_url}/?conference=BVA#{conference_id}@#{host}&name=#{name}&pin=#{pin}&callType=video&join=1"
  end

  def pin_hash(seed)
    "0x#{Digest::SHA256.hexdigest(seed)}".to_i(16).to_s
  end

  def pin_key
    ENV["VIRTUAL_HEARING_PIN_KEY"] || fail(PINKeyMissingError, message: COPY::PIN_KEY_MISSING_ERROR_MESSAGE)
  end

  def conference_id
    @conference_id.presence ||= VirtualHearings::SequenceConferenceId.next
  end

  def base_url
    "https://#{host}#{path}"
  end

  def host
    ENV["VIRTUAL_HEARING_URL_HOST"] || "vc.va.gov"
  end

  def path
    ENV["VIRTUAL_HEARING_URL_PATH"] || "/webapp"
  end
end
