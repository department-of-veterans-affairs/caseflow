# frozen_string_literal: true

describe Hearings::HearingEmailStatusJob do
  describe "#perform" do
    subject { Hearings::HearingEmailStatusJob.new.perform }

    let!(:appellant_sent_hearing_email_event) do
      create(
        :sent_hearing_email_event,
        :with_virtual_hearing,
        recipient_role: "appellant"
      )
    end

    let!(:representative_sent_hearing_email_event) do
      create(
        :sent_hearing_email_event,
        :with_virtual_hearing,
        recipient_role: "representative"
      )
    end

    let(:success_status) { "sent" }
    let(:invalid_status) { "invalid" }
    let(:failure_status) { "failed" }

    context "when GovDelivery throws an error" do
      it "captures error and allows job to continue running" do
        allow(ExternalApi::GovDeliveryService)
          .to receive(:get_sent_status_from_event)
          .once.with(email_event: appellant_sent_hearing_email_event)
          .and_raise(Caseflow::Error::GovDeliveryApiError.new(code: 401, message: "error"))

        allow(ExternalApi::GovDeliveryService)
          .to receive(:get_sent_status_from_event)
          .once.with(email_event: representative_sent_hearing_email_event)
          .and_return(success_status)

        subject

        expect(appellant_sent_hearing_email_event.reload.send_successful)
          .to eq(nil)
        expect(appellant_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
        expect(representative_sent_hearing_email_event.reload.send_successful)
          .to eq(true)
        expect(appellant_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
      end
    end

    context "when GovDelivery reports invalid status" do
      it "handles invalid status and does not update send_successful" do
        allow(ExternalApi::GovDeliveryService)
          .to receive(:get_sent_status_from_event)
          .once.with(email_event: appellant_sent_hearing_email_event)
          .and_return(success_status)

        allow(ExternalApi::GovDeliveryService)
          .to receive(:get_sent_status_from_event)
          .once.with(email_event: representative_sent_hearing_email_event)
          .and_return(invalid_status)

        subject

        expect(appellant_sent_hearing_email_event.reload.send_successful)
          .to eq(true)
        expect(appellant_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
        expect(representative_sent_hearing_email_event.reload.send_successful)
          .to eq(nil)
        expect(representative_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
      end
    end

    context "when email event belongs to a non-virtual hearing" do
      let!(:non_virtual_sent_hearing_email_event) do
        create(:sent_hearing_email_event)
      end

      it "does not set sent_successful" do
        subject

        expect(non_virtual_sent_hearing_email_event.reload.send_successful)
          .to eq(nil)
        expect(non_virtual_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
      end
    end

    context "when GovDelivery reports failure status" do
      it "handles failure status and sets send_successful", :aggregate_failures do
        allow(ExternalApi::GovDeliveryService)
          .to receive(:get_sent_status_from_event)
          .once.with(email_event: appellant_sent_hearing_email_event)
          .and_return(failure_status)

        allow(ExternalApi::GovDeliveryService)
          .to receive(:get_sent_status_from_event)
          .once.with(email_event: representative_sent_hearing_email_event)
          .and_return(failure_status)

        subject

        expect(appellant_sent_hearing_email_event.reload.send_successful)
          .to eq(false)
        expect(appellant_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
        expect(appellant_sent_hearing_email_event.sent_hearing_admin_email_event)
          .not_to be_nil
        expect(representative_sent_hearing_email_event.reload.send_successful)
          .to eq(false)
        expect(representative_sent_hearing_email_event.send_successful_checked_at)
          .not_to be_nil
        expect(representative_sent_hearing_email_event.sent_hearing_admin_email_event)
          .not_to be_nil
     end
    end
  end
end
