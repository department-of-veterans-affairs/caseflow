# frozen_string_literal: true

describe Memberships::SendMembershipRequestMailerJob do
  let(:requestor) { create(:default_user) }
  let(:camo_org) { VhaCamo.singleton }
  let(:organization) { camo_org }
  let(:membership_requests) { [create(:membership_request, requestor: requestor, organization: organization)] }
  let(:mailer_parameters) do
    {
      requestor: requestor,
      requests: membership_requests,
      subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_REQUESTOR_SUBMITTED
    }
  end
  let(:approved_and_denied_params) do
    {
      requestor: requestor,
      accessible_groups: requestor.organizations.map(&:name),
      organization_name: camo_org.name,
      pending_organization_request_names: ["Org 1", "Org 2"]
    }
  end

  let(:error) do
    StandardError.new("Error")
  end

  before do
    allow(Raven).to receive(:capture_exception) { @raven_called = true }
  end

  subject { described_class.perform_now(type, mailer_parameters) }

  describe "#perform" do
    context "the type is UserRequestCreated" do
      let(:type) { "UserRequestCreated" }

      it "sends a status update email to the requestor" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is AdminRequestMade" do
      let(:type) { "AdminRequestMade" }

      let(:mailer_parameters) do
        {
          subject: COPY::VHA_MEMBERSHIP_REQUEST_SUBJECT_LINE_VHA_ADMIN_REQUEST_RECEIVED,
          to: COPY::VHA_BENEFIT_EMAIL_ADDRESS,
          organization_name: organization.name
        }
      end

      it "sends a status update email to the camo admin" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is VhaBusinessLineApproved" do
      let(:type) { "VhaBusinessLineApproved" }
      let(:mailer_parameters) { approved_and_denied_params }

      it "sends a request status approved email to the requestor" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is VhaBusinessLineDenied" do
      let(:type) { "VhaBusinessLineDenied" }
      let(:mailer_parameters) { approved_and_denied_params }

      it "sends a request status denied email to the requestor" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is VhaPredocketApproved" do
      let(:type) { "VhaPredocketApproved" }
      let(:mailer_parameters) { approved_and_denied_params }

      it "sends a request status approved email to the requestor" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "the type is VhaPredocketDenied" do
      let(:type) { "VhaPredocketDenied" }
      let(:mailer_parameters) { approved_and_denied_params }

      it "sends a request status denied email to the requestor" do
        expect { subject }.to change {
          ActionMailer::Base.deliveries.count
        }.by 1
      end
    end

    context "no type provided" do
      let(:type) { nil }

      it "throws an error" do
        expect { subject }.to raise_error do |error|
          expect(error).to be_a(ArgumentError)
        end
      end
    end

    context "a Datadog metric is captured" do
      let(:type) { "UserRequestCreated" }
      let(:email_message) { instance_double(GovDelivery::TMS::EmailMessage) }
      let(:response) { instance_double("Response") }

      it "Calls the DataDogService in the external_message_id method" do
        allow_any_instance_of(ActionMailer::Parameterized::MessageDelivery).to receive(:deliver_now!)
          .and_return(email_message)
        allow(email_message).to receive(:is_a?).with(GovDelivery::TMS::EmailMessage).and_return(true)
        allow(email_message).to receive(:response).and_return(response)
        allow(response).to receive(:body).and_return({})
        allow(response).to receive(:status).and_return("200 Good")
        expect(DataDogService).to receive(:emit_gauge).with(
          app_name: "caseflow_job",
          metric_group: Memberships::SendMembershipRequestMailerJob.name.underscore,
          metric_name: "runtime",
          metric_value: anything
        ).once
        subject
      end
    end

    context "an error is thrown" do
      let(:type) { "UserRequestCreated" }
      it "rescues error and logs to sentry" do
        allow_any_instance_of(MembershipRequestMailer).to receive(:user_request_created).and_raise(error)
        subject do
          expect(@raven_called).to eq(true)
        end
      end
    end

    context "an error is thrown" do
      let(:type) { "UserRequestCreated" }
      it "rescues error and logs it with the Rails Logger" do
        allow_any_instance_of(MembershipRequestMailer).to receive(:user_request_created).and_raise(error)
        subject do
          expect(Rails.logger).to have_received(:warn).with("Error").once
        end
      end
    end
  end
end
