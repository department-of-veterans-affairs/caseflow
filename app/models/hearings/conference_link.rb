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
    return guest_pin_long if !guest_pin_long.nil?

    link_service = VirtualHearings::LinkService.new
    update!(guest_pin_long: link_service.guest_pin)
    guest_pin_long
  end

  def guest_link
    return guest_hearing_link if !guest_hearing_link.to_s.empty?

    if !alias_name.nil?
      link_service = VirtualHearings::LinkService.new(alias_name)
      update!(guest_hearing_link: link_service.guest_link)
    elsif !alias_with_host.nil?
      link_service = VirtualHearings::LinkService.new(alias_with_host.split("@")[0].split("A")[1])
      update!(guest_hearing_link: link_service.guest_link, alias: link_service.get_conference_id)
    end
    guest_hearing_link
  end

  private

  def generate_links_and_pins
    Rails.logger.info(
      "Trying to create conference links for Hearing Day Id: #{hearing_day_id}."
    )
    begin
      link_service = VirtualHearings::LinkService.new
      update!(
        alias: link_service.get_conference_id,
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
end
