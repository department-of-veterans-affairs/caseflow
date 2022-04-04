require 'govdelivery-tms'
require 'mail'
require 'mail/check_delivery_params'

module GovDelivery::TMS
  module Mail
    # Use TMS from the mail gem or ActionMailer as a delivery method.
    #
    #   # Gemfile
    #   gem 'govdelivery-tms', :require=>'govdelivery/tms/mail/delivery_method'
    #
    #   # config/environment.rb
    #   config.action_mailer.delivery_method = :govdelivery_tms
    #   config.action_mailer.govdelivery_tms_settings = {
    #     :auth_token=>'auth_token',
    #     :api_root=>'https://stage-tms.govdelivery.com'
    #     }
    class DeliveryMethod
      include ::Mail::CheckDeliveryParams

      def initialize(values)
        self.settings = values
      end

      attr_accessor :settings

      def deliver!(mail)
        fail GovDelivery::TMS::Errors::NoRelation.new('email_messages', client) unless client.respond_to?(:email_messages)

        body = case
               when mail.html_part
                 mail.html_part.body
               when mail.text_part
                 mail.text_part.body
               else
                 mail.body
               end.decoded

        message_params              = {
          subject: mail.subject,
          body:    body
        }
        message_params[:from_email] = mail.from.first unless mail.from.blank?
        message_params[:from_name]  = mail[:from].display_names.first unless mail[:from].blank?

        tms_message = client.email_messages.build(message_params)

        mail.to.each { |recip| tms_message.recipients.build(email: recip) }
        tms_message.post!
        tms_message
      end

      def client
        @client ||= GovDelivery::TMS::Client.new(settings[:auth_token], settings)
      end
    end
  end
end

if defined?(ActionMailer)
  ActionMailer::Base.add_delivery_method :govdelivery_tms, GovDelivery::TMS::Mail::DeliveryMethod, auth_token: nil,
                                                                                                   logger:                                                               ActionMailer::Base.logger,
                                                                                                   api_root:                                                             GovDelivery::TMS::Client::DEFAULTS[:api_root]
end
