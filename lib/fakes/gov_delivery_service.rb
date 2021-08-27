# frozen_string_literal: true

class Fakes::GovDeliveryService
  FAKE_STATUS = "sent"

  class << self
    def get_sent_status_from_event(*)
      FAKE_STATUS
    end

    def get_recipients_from_event(*)
      [{}]
    end

    def get_sent_status(*)
      FAKE_STATUS
    end

    def get_recipients(*)
      [{}]
    end
  end
end
