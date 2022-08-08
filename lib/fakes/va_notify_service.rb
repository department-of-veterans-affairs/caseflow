# frozen_string_literal: true

class Fakes::VANotifyService < ExternalApi::VANotifyService

  def self.fake_email_response
    {
      reference: "string",
      template_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      personalisation: {
        full_name: "John Smith",
        claim_id: "123456"
      },
      scheduled_for: "string",
      billing_code: "string",
      email_reply_to_id: "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      email_address: "string"
    }
  end
end
