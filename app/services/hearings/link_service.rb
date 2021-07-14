# frozen_string_literal: true

require "digest"

##
# Service for generating new guest and host virtual hearings links
##
class Hearings::LinkService
  class PINKeyMissingError < StandardError; end
  class URLHostMissingError < StandardError; end
  class URLPathMissingError < StandardError; end
  class PINMustBePresentError < StandardError; end

  def initialize(conference_id = nil)
    @conference_id = conference_id
  end

  def host_link
    link(host_pin)
  end

  def guest_link
    link(guest_pin)
  end

  def host_pin
    pin_hash("#{pin_key}#{conference_id}")[0..6]
  end

  def guest_pin
    pin_hash("#{conference_id}#{pin_key}")[0..9]
  end

  def alias_with_host
    "BVA#{conference_id}@#{host}"
  end

  private

  def link(pin)
    fail PINMustBePresentError if pin.blank?

    "#{base_url}/?conference=#{alias_with_host}&pin=#{pin}&callType=video"
  end

  def pin_hash(seed)
    "0x#{Digest::SHA256.hexdigest(seed)}".to_i(16).to_s
  end

  def base_url
    "https://#{host}#{path}"
  end

  def conference_id
    @conference_id = Hearings::SequenceConferenceId.next if @conference_id.blank?
    @conference_id
  end

  def pin_key
    ENV["VIRTUAL_HEARING_PIN_KEY"] || fail(PINKeyMissingError, message: COPY::PIN_KEY_MISSING_ERROR_MESSAGE)
  end

  def host
    ENV["VIRTUAL_HEARING_URL_HOST"] || fail(URLHostMissingError, COPY::URL_HOST_MISSING_ERROR_MESSAGE)
  end

  def path
    ENV["VIRTUAL_HEARING_URL_PATH"] || fail(URLPathMissingError, COPY::URL_PATH_MISSING_ERROR_MESSAGE)
  end
end
