# frozen_string_literal: true

describe VirtualHearings::CreateConferenceJob, :all_dbs do
  include ActiveJob::TestHelper

  context ".perform" do
    let(:hearing) { create(:hearing, regional_office: "RO06") }
    let(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
    let(:create_job) do
      VirtualHearings::CreateConferenceJob.new(
        hearing_id: virtual_hearing.hearing_id,
        hearing_type: virtual_hearing.hearing_type,
        updated_by_id: virtual_hearing.created_by.id
      )
    end

    subject { create_job }

    it "creates a conference", :aggregate_failures do
      subject.perform_now

      virtual_hearing.reload
      expect(virtual_hearing.conference_id).to eq(9001)
      expect(virtual_hearing.status).to eq(:active)
      expect(virtual_hearing.alias).to eq("0000001")
      expect(virtual_hearing.host_pin.nil?).to eq(false)
      expect(virtual_hearing.guest_pin.nil?).to eq(false)
    end

    it "sends confirmation emails if success and is processed", :aggregate_failures do
      subject.perform_now

      virtual_hearing.reload
      expect(virtual_hearing.veteran_email_sent).to eq(true)
      expect(virtual_hearing.judge_email_sent).to eq(true)
      expect(virtual_hearing.representative_email_sent).to eq(true)
      expect(virtual_hearing.establishment.processed?).to eq(true)
    end

    it "creates sent email events", :aggregate_failuress do
      subject.perform_now

      virtual_hearing.reload
      expect(virtual_hearing.hearing.email_events.count).to eq(3)
      expect(virtual_hearing.hearing.email_events.is_confirmation.count).to eq(3)
      expect(virtual_hearing.hearing.email_events.sent_to_veteran.count).to eq(1)
      expect(virtual_hearing.hearing.email_events.sent_to_representative.count).to eq(1)
      expect(virtual_hearing.hearing.email_events.sent_to_judge.count).to eq(1)
    end

    it "logs success to datadog" do
      expect(DataDogService).to receive(:increment_counter).with(
        hash_including(
          metric_name: "created_conference.successful",
          metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
          attrs: { hearing_id: hearing.id }
        )
      )

      subject.perform_now
    end

    context "veteran email fails to send" do
      before do
        expected_mailer_args = {
          mail_recipient: having_attributes(title: MailRecipient::RECIPIENT_TITLES[:veteran]),
          virtual_hearing: instance_of(VirtualHearing)
        }

        allow(VirtualHearingMailer).to receive(:confirmation).with(any_args).and_call_original
        allow(VirtualHearingMailer).to(
          receive(:confirmation)
            .with(expected_mailer_args)
            .and_raise(GovDelivery::TMS::Request::Error.new(500))
        )
      end

      it "fails to send any emails", :aggregate_failures do
        subject.perform_now

        virtual_hearing.reload
        expect(virtual_hearing.veteran_email_sent).to eq(false)
        expect(virtual_hearing.judge_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
        expect(virtual_hearing.establishment.processed?).to eq(false)
      end

      it "retry is called on job" do
        expect do
          perform_enqueued_jobs do
            VirtualHearings::CreateConferenceJob.perform_later(subject.arguments.first)
          end
        end.to(
          have_performed_job(VirtualHearings::CreateConferenceJob)
            .exactly(5)
            .times
        )
      end
    end

    context "conference creation fails" do
      let(:fake_pexip) { Fakes::PexipService.new(status_code: 400) }

      before do
        allow(PexipService).to receive(:new).and_return(fake_pexip)
      end

      after do
        clear_enqueued_jobs
      end

      it "job goes back on queue and logs if error", :aggregate_failures do
        expect(Rails.logger).to receive(:error).exactly(5).times

        expect do
          perform_enqueued_jobs do
            VirtualHearings::CreateConferenceJob.perform_later(subject.arguments.first)
          end
        end.to(
          have_performed_job(VirtualHearings::CreateConferenceJob)
            .exactly(5)
            .times
        )

        virtual_hearing.establishment.reload
        expect(virtual_hearing.establishment.error.nil?).to eq(false)
        expect(virtual_hearing.establishment.attempted?).to eq(true)
        expect(virtual_hearing.establishment.processed?).to eq(false)
      end

      it "logs failure to datadog" do
        expect(DataDogService).to receive(:increment_counter).with(
          hash_including(
            metric_name: "created_conference.failed",
            metric_group: Constants.DATADOG_METRICS.HEARINGS.VIRTUAL_HEARINGS_GROUP_NAME,
            attrs: { hearing_id: hearing.id }
          )
        )

        subject.perform_now
      end

      it "does not create sent email events" do
        subject.perform_now

        virtual_hearing.reload
        expect(virtual_hearing.hearing.email_events.count).to eq(0)
      end
    end
  end
end
