module GovDelivery::TMS #:nodoc:
  #  A Webhook gets invoked when a recipient enters a queued or final state
  #
  # @attr url [String] The URL to POST webhooks to
  # @attr event_type  'sending', 'inconclusive', 'blacklisted', 'sent', 'canceled', or 'failed'
  #
  # @example
  #    webhook = client.webhooks.build(:url => 'http://your.url', :event_type => 'failed')
  #    webhook.post
  #    webhook.get
  class Webhook
    include InstanceResource

    # @!parse attr_accessor :url, :event_type
    writeable_attributes :url, :event_type

    # @!parse attr_reader :created_at, :updated_at
    readonly_attributes :created_at, :updated_at
  end
end
