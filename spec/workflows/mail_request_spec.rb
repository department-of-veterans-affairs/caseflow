# frozen_string_literal: true

describe MailRequest do
  let(:valid_request) { MailRequest.new(mail_request_params) }
  let(:invalid_request) { MailRequest.new(invalid_mail_request_params) }
  let(:mail_request_params) do
    ActionController::Parameters.new({
      recipient_info: [
        {
          recipient_type: "person",
          first_name: "Bob",
          last_name: "Smithmetz",
          participant_id: "487470002",
          destination_type: "domesticAddress",
          address_line_1: "1234 Main Street",
          treat_line_2_as_addressee: false,
          treat_line_3_as_addressee: false,
          city: "Orlando",
          state: "FL",
          postal_code: "12345",
          country_code: "US"
        }
      ]
    })
  end
  let(:invalid_mail_request_params) do
    ActionController::Parameters.new({
      recipient_info: [
        {
          recipient_type: "",
          last_name: "Smithmetz",
          participant_id: "487470002",
          destination_type: "domesticAddress",
          address_line_1: "1234 Main Street",
          treat_line_2_as_addressee: false,
          treat_line_3_as_addressee: false,
          city: "Orlando",
          state: "FL",
          postal_code: "12345",
          country_code: "US"
        }
      ]
    })
  end

  describe "#call" do
    context "when valid parameters are available" do
      it "it checks if self is valid" do

      end
    end
  end
end
