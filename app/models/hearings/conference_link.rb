# frozen_string_literal: true

class ConferenceLink < CaseflowRecord
  class NoAliasWithHostPresentError < StandardError; end
  class LinkMismatchError < StandardError; end

  include UpdatedByUserConcern
  include CreatedByUserConcern

  after_create :generate_links_and_pins

  class << self
    def client_host_or_default
      ENV["VIRTUAL_HEARING_URL_HOST"] || "care.evn.va.gov"
    end

    def formatted_alias(alias_name)
      "BVA#{alias_name}@#{client_host_or_default}"
    end

    def base_url
      "https://#{client_host_or_default}/bva-app/"
    end
  end

  alias_attribute :alias_name, :alias

  belongs_to :hearing_day

  # Override the host pin
  def host_pin
    host_pin_long || self[:host_pin]
  end

  def host_link
    @full_host_link ||= "#{ConferenceLink.base_url}?join=1&media=&escalate=1&" \
    "conference=#{alias_with_host}&" \
    "pin=#{host_pin}&role=host"
  end

  def guest_pin
    if guest_pin_long.nil?
      link_service = VirtualHearings::LinkService.new
      update!(guest_pin_long: link_service.guest_pin)
    else
      guest_pin_long
    end
  end

  def guest_link
    if guest_hearing_link.nil?
      if guest_pin_long.nil?
         guest_pin
      end
      url = "#{ConferenceLink.base_url}?join=1&media=&escalate=1&" \
      "conference=#{alias_with_host}&" \
      "pin=#{guest_pin}&callType=video"
      byebug
      update!(guest_hearing_link: url)
    else
      guest_hearing_link
    end
  end

  private

  def generate_links_and_pins
    Rails.logger.info(
      "Trying to create conference links for Hearing Day Id: #{hearing_day_id}."
    )
    begin
      link_service = VirtualHearings::LinkService.new
      update!(
        host_link: link_service.host_link,
        host_pin_long: link_service.host_pin,
        alias_with_host: link_service.alias_with_host,
        guest_hearing_link: link_service.guest_link,
        guest_pin_long: link_service.guest_pin
      )
    rescue VirtualHearings::LinkService::PINKeyMissingError,
      VirtualHearings::LinkService::URLHostMissingError,
      VirtualHearings::LinkService::URLPathMissingError => error
      Raven.capture_exception(error: error)
      raise error
    end
  end

  def formatted_alias(alias_name)
    "BVA#{alias_name}@#{client_host_or_default}"
  end

  # Returns a random host and guest pin
  def generate_conference_pins
    self.host_pin_long = "#{rand(1_000_000..9_999_999).to_s[0..9]}#"
  end
end
