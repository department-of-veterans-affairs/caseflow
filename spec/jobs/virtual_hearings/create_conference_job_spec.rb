# frozen_string_literal: true

describe VirtualHearings::CreateConferenceJob do
  include ActiveJob::TestHelper

  context ".perform" do
    let(:hearing) { create(:hearing, regional_office: "RO06") }
    let!(:virtual_hearing) { create(:virtual_hearing, hearing: hearing) }
    let(:create_job) do
      VirtualHearings::CreateConferenceJob.new(
        hearing_id: hearing.id,
        hearing_type: hearing.class.name
      )
    end
    let(:pexip_url) { "fake.va.gov" }
    before do
      stub_const("ENV", "PEXIP_CLIENT_HOST" => pexip_url)
    end

    subject { create_job }

    it "creates a conference", :aggregate_failures do
      subject.perform_now

      virtual_hearing.reload
      expect(virtual_hearing.conference_id).to eq(9001)
      expect(virtual_hearing.status).to eq(:active)
      expect(virtual_hearing.alias).to eq("0000001")
      expect(virtual_hearing.alias_with_host).to eq("BVA0000001@#{pexip_url}")
      expect(virtual_hearing.host_pin.to_s.length).to eq(8)
      expect(virtual_hearing.guest_pin.to_s.length).to eq(11)
    end

    it "sends confirmation emails if success and is processed", :aggregate_failures do
      subject.perform_now

      virtual_hearing.reload
      expect(virtual_hearing.appellant_email_sent).to eq(true)
      expect(virtual_hearing.judge_email_sent).to eq(true)
      expect(virtual_hearing.representative_email_sent).to eq(true)
      expect(virtual_hearing.establishment.processed?).to eq(true)
    end

    it "creates sent email events", :aggregate_failuress do
      subject.perform_now

      virtual_hearing.reload
      expect(virtual_hearing.hearing.email_events.count).to eq(3)
      expect(virtual_hearing.hearing.email_events.is_confirmation.count).to eq(3)
      expect(virtual_hearing.hearing.email_events.sent_to_appellant.count).to eq(1)
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

    context "appellant email fails to send" do
      before do
        expected_mailer_args = {
          mail_recipient: having_attributes(title: MailRecipient::RECIPIENT_TITLES[:appellant]),
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
        expect(virtual_hearing.appellant_email_sent).to eq(false)
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
            .exactly(10)
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
        expect(Rails.logger).to receive(:error).exactly(11).times

        expect do
          perform_enqueued_jobs do
            VirtualHearings::CreateConferenceJob.perform_later(subject.arguments.first)
          end
        end.to(
          have_performed_job(VirtualHearings::CreateConferenceJob)
            .exactly(10)
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

    context "when the virtual hearing is not immediately available" do
      let(:virtual_hearing) { nil }

      after do
        clear_enqueued_jobs
      end

      it "throws an error" do
        # VirtualHearings::CreateConferenceJob#perform_now doesn't throw because the error is caught
        # by retry_on.
        expect { subject.perform(subject.arguments.first) }.to raise_error(
          VirtualHearings::CreateConferenceJob::VirtualHearingNotCreatedError
        )
      end

      it "retries job" do
        expect do
          perform_enqueued_jobs do
            VirtualHearings::CreateConferenceJob.perform_later(subject.arguments.first)
          end
        end.to(
          have_performed_job(VirtualHearings::CreateConferenceJob)
            .exactly(10)
            .times
        )
      end
    end

    context "when the virtual hearing is cancelled already" do
      let!(:virtual_hearing) do
        create(
          :virtual_hearing,
          :all_emails_sent,
          :initialized,
          hearing: hearing,
          status: :cancelled
        )
      end

      after do
        clear_enqueued_jobs
      end

      it "throws an error" do
        # VirtualHearings::CreateConferenceJob#perform_now doesn't throw because the error is caught
        # by retry_on.
        expect { subject.perform(subject.arguments.first) }.to raise_error(
          VirtualHearings::CreateConferenceJob::VirtualHearingRequestCancelled
        )
      end

      it "does not retry job" do
        expect do
          perform_enqueued_jobs do
            VirtualHearings::CreateConferenceJob.perform_later(subject.arguments.first)
          end
        end.to(
          have_performed_job(VirtualHearings::CreateConferenceJob)
            .exactly(:once)
        )
      end
    end

    context "for a legacy hearings" do
      let(:appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(:case)
        )
      end
      let!(:representative) do
        create(
          :representative,
          repfirst: "Serrif",
          replast: "Gnest",
          repkey: appeal.vacols_id
        )
      end
      let(:hearing) { create(:legacy_hearing, appeal: appeal) }

      context "when representative is different in VACOLS and VBMS" do
        it "uses the representative in VBMS" do
          # Sanity check that calling `LegacyAppeal#representative_name` returns the
          # VACOLS value if the `RequestStore.store[:application]` isn't set
          expect(appeal.representative_name).to eq("Serrif Gnest")

          expect(MailRecipient).to(
            receive(:new)
              .with(instance_of(Hash))
              .twice
              .and_call_original
          )
          expect(MailRecipient).to(
            receive(:new)
              .with(
                hash_including(
                  name: FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME,
                  title: MailRecipient::RECIPIENT_TITLES[:representative]
                )
              )
              .once
              .and_call_original
          )

          subject.perform_now
        end
      end
    end
  end
end
