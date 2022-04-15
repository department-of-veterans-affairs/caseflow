# frozen_string_literal: true

# Tracks the progress of the job responsible for creating
# the conference link conference in Pexip.

class ConferenceLink < CaseflowRecord

  class NoAliasWithHostPresentError < StandardError; end
  class LinkMismatchError < StandardError; end
  class ConferenceLinkGenerationFailed < StandardError; end
  include UpdatedByUserConcern
  include Hearings::EnsureCurrentUserIsSet

  class << self
    def client_host_or_default
      ENV["PEXIP_CLIENT_HOST"] || "care.evn.va.gov"
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
  belongs_to :created_by_id, class_name: "User"

  attr_reader :conference_link

  # After a certain point after this change gets merged, alias_with_host will never be nil
  # so we can rid of this logic then
  def formatted_alias_or_alias_with_host
    alias_with_host.nil? ? ConferenceLink.formatted_alias(alias_name) : alias_with_host
  end

  # Returns a random host pin
  def generate_conference_pins
    self.host_pin_long = "#{rand(1_000_000..9_999_999).to_s[0..9]}#"
  end

  # Override the host pin
  def host_pin
    host_pin_long || self[:host_pin]
  end

  def host_link
    return host_hearing_link if host_hearing_link.present?

    "#{ConferenceLink.base_url}?join=1&media=&escalate=1&" \
    "conference=#{formatted_alias_or_alias_with_host}&" \
    "pin=#{host_pin}&role=host"
  end

  def set_conference_link(hearing_day, hearing_day_id)
    case hearing_day_id
    when Hearing.name
      @conference_link = Hearing.find(hearing_day).conference_link
    when LegacyHearing.name
      @conference_link = LegacyHearing.find(hearing_day).conference_link
    else
      fail ArgumentError, "Invalid hearing day id supplied to job of set conference link: `#{hearing_day_id}`"
    end

    ConferenceLinkNotCreatedError if conference_link.nil?
    ConferenceLinkRequestCancelled if virtual_hearing.cancelled?
  end

  def create_conference_link_datadog_tags
    datadog_metric_info.merge(attrs: { hearing_day_id: conference_link.hearing_day_id })
  end

  # Creates the conference link.
  def create_conference_link
    link_service = ConferenceLink::LinkServices.new
    conference_link.update!(
      host_hearing_link: link_service.host_link,
      host_pin_long: link_service.host_pin,
      alias_with_host: link_service.alias_with_host
    )
    assign_conference_link_alias_and_pins if should_initialize_alias_and_pins?
    pexip_response = create_pexip_conference_link
  end

  def should_initialize_alias_and_pins?
    conference_link.alias.nil? || conference_link.host_pin.nil?
  end

  def assign_conference_link_alias_and_pins
    # Using pessimistic locking here because no other processes should be reading
    # the record when maximum is being calculated.
    conference_link.with_lock do
      max_alias = ConferenceLink.maximum(:alias)
      conference_alias = max_alias ? (max_alias.to_i + 1).to_s.rjust(7, "0") : "0000001"
      conference_link.alias = conference_alias
      conference_link.alias_with_host = ConferenceLink.formatted_alias(conference_alias)
      conference_link.generate_conference_pins
      conference_link.save!
    end
  end

  def create_pexip_conference_link
    client.create_conference(
      host_pin: conference_link.host_pin,
      name: conference_link.alias
    )
  end

  def pexip_error_display(response)
    "(#{response.error.code}) #{response.error.message}"
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore.store[:current_user]
  end

  def updated_by_user_css_id
    RequestStore.store[:current_user].css_id.upcase
  end
end