# frozen_string_literal: true

describe MailRequest, :postgres do
  let(:mail_request_params) do
    ActionController::Parameters.new(
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
    )
  end

  let(:invalid_mail_request_params) do
    ActionController::Parameters.new(
      recipient_type: nil,
      last_name: "Smithmetz",
      participant_id: "487470002",
      destination_type: "domesticAddress",
      address_line_1: "1234 Main Street",
      treat_line_2_as_addressee: false,
      treat_line_3_as_addressee: false,
      city: "Orlando",
      state: "FL",
      postal_code: nil,
      country_code: "US"
    )
  end

  shared_examples "mail request has valid attributes" do
    let(:mail_request_spec_object) { build(:mail_request) }
    it "is valid with valid attributes" do
      expect(mail_request_spec_object).to be_valid
    end
  end

  shared_examples "Valid mail request called upon creates desired artifacts" do
    before do
      RequestStore.store[:current_user] = User.system_user
    end

    it "creates a vbms_distribution" do
      expect { subject }.to change(VbmsDistribution, :count).by(1)
    end

    it "creates a vbms_distribution_destination" do
      expect { subject }.to change(VbmsDistributionDestination, :count).by(1)
    end
  end

  let(:mail_request_spec_object_1) { build(:mail_request, :nil_recipient_type) }
  include_examples "mail request has valid attributes"
  it "is not valid without a recipient type" do
    expect(mail_request_spec_object_1).to_not be_valid
  end

  describe "#call" do
    context "when valid parameters are passed into the mail requests initialize method." do
      subject { described_class.new(mail_request_params).call }

      include_examples "Valid mail request called upon creates desired artifacts"
    end

    context "When the recipient_type param is 'ro-colocated" do
      let(:ro_colocated_mail_request_params) do
        ActionController::Parameters.new(
          recipient_type: "ro-colocated",
          claimant_station_of_jurisdiction: "123",
          poa_code: "02A",
          name: "POA Name",
          destination_type: "derived"
        )
      end

      subject { described_class.new(ro_colocated_mail_request_params).call }

      include_examples "Valid mail request called upon creates desired artifacts"
    end

    context "when invalid parameters are passed into the mail requests initialize method." do
      subject { described_class.new(invalid_mail_request_params).call }
      it "raises an error" do
        expect { subject }.to raise_error(Caseflow::Error::MissingRecipientInfo)
      end
    end
  end
end
