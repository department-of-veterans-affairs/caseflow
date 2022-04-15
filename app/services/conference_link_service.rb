
# frozen_string_literal: true

##
# Conference Link Service is used to generate the conference link through pexip that is called upon
# by conference_link.rb for the create method which is used for the hearing_day.rb model.
# In order for conference link service to work, a virtual hearing day must be available to which a
# hearing with a VLJ must can be used to join by a video conference from any device without having 
# to travel to a VA facility.
# Caseflow integrates with a conferencing solution called Pexip to create conference rooms
# Comment below this line can be discarded in future 04/11/2022 after conference link works.
# and uses GovDelivery to send email notifications to participants of hearing
# which includes the veteran/appellant, judge, and representative.
#
# When a hearing coordinator switches a hearing to
# virtual hearing, CreateConferenceJob is kicked off to create a conference and send out
# emails to participants including the link to video conference as well as other details about
# the hearing. DeleteConferencesJob is kicked off to delete the conference resource
# when the the virtual hearing is cancelled or after the hearing takes place.
#
##
# frozen_string_literal: true

require "digest"

##
# Service for generating new guest and host virtual hearings links
##
class ConferenceLinkServices

  class ConferenceLink::LinkService
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

    def host_pin
      pin_hash("#{pin_key}#{conference_id}")[0..6]
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
      @conference_id = ConferenceLink::SequenceConferenceId.next if @conference_id.blank?
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

  class ConferenceLinkSerializer
    include FastJsonapi::ObjectSerializer
    attr_reader :conference_link
    attribute :alias_with_host
    attribute :host_pin
    attribute :host_link
    attribute :id
    attribute :alias
    attribute :conference_deleted
    attribute :conference_id
    attribute :created_at
    attribute :host_hearing_link
    attribute :host_pin_long
    attribute :updated_at
    attribute :updated_by_id
  end

  class ConferenceLink
    attr_accessor

    def initialize(alias_with_host, host_pin, host_link, id, conference_deleted, 
    conference_id, created_at, host_hearing_link, host_pin_long, updated_at, updated_by_id)

      @alias_with_host = alias_with_host
      @host_pin = host_pin
      @host_link = host_link
      @id = id
      @conference_deleted = conference_deleted
      @conference_id = conference_id
      @created_at = created_at
      @host_hearing_link = host_hearing_link
      @host_pin_long = host_pin_long
      @updated_at = updated_at
      @updated_by_id = updated_by_id
    end
  end

  class ConferenceLink::PexipClient
    def client
      @client ||= PexipService.new(
        host: ENV["PEXIP_MANAGEMENT_NODE_HOST"],
        port: ENV["PEXIP_MANAGEMENT_NODE_PORT"],
        user_name: ENV["PEXIP_USERNAME"],
        password: ENV["PEXIP_PASSWORD"],
        client_host: ENV["PEXIP_CLIENT_HOST"]
      )
    end
  end
end