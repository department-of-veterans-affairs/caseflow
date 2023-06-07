# frozen_string_literal: true

describe MailRequest, :postgres do
  let(:mail_request_params) do
    ActionController::Parameters.new(
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
        })
  end
  let(:invalid_mail_request_params) do
    ActionController::Parameters.new(
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
        })
  end
  let(:valid_request) { MailRequest.new(mail_request_params) }
  let(:invalid_request) { MailRequest.new(invalid_mail_request_params) }

  describe "#call" do
    context "when valid parameters are passed into the mail requests initialize method." do
      subject { described_class.new(mail_request_params).call }
      it "creates a vbms_distribution" do
        expect{ subject }.to change(VbmsDistribution, :count).by(1)
      end

      it "creates a vbms_distribution_destination" do
        expect{ subject }.to change(VbmsDistributionDestination, :count).by(1)
      end
    end

    context "when invalid parameters are passed into the mail requests initialize method." do
      subject { described_class.new(invalid_mail_request_params).call }
      it "raises an error" do
        expect { subject }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

  end
end
