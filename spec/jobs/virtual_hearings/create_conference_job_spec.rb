# frozen_string_literal: true

describe VirtualHearings::CreateConferenceJob do
  include ActiveJob::TestHelper

  URL_HOST = "example.va.gov"
  URL_PATH = "/sample"
  PIN_KEY = "mysecretkey"

  context ".perform" do
    let(:current_user) { create(:user, roles: ["Build HearSched"]) }
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
      User.authenticate!(user: current_user)
    end

    subject { create_job }

    shared_examples "sent email event objects are created" do
      it "creates sent email events", :aggregate_failures do
        subject.perform_now

        virtual_hearing.reload
        expect(virtual_hearing.hearing.email_events.count).to eq(3)
        expect(virtual_hearing.hearing.email_events.is_confirmation.count).to eq(3)
        expect(virtual_hearing.hearing.email_events.sent_to_appellant.count).to eq(1)
        expect(virtual_hearing.hearing.email_events.sent_to_representative.count).to eq(1)
        expect(virtual_hearing.hearing.email_events.sent_to_judge.count).to eq(1)
      end
    end

    shared_examples "confirmation emails are sent" do
      it "sends confirmation emails if success and is processed", :aggregate_failures do
        subject.perform_now

        virtual_hearing.reload
        expect(virtual_hearing.appellant_email_sent).to eq(true)
        expect(virtual_hearing.judge_email_sent).to eq(true)
        expect(virtual_hearing.representative_email_sent).to eq(true)
        expect(virtual_hearing.establishment.processed?).to eq(true)
      end
    end

    shared_examples "job is retried" do
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

    shared_examples "raises error" do |error|
      # VirtualHearings::CreateConferenceJob#perform_now doesn't throw because the error is caught
      # by retry_on.
      it "raises error" do
        expect { subject.perform(subject.arguments.first) }.to raise_error(error)
      end
    end

    shared_examples "does not retry job" do
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

    include_examples "confirmation emails are sent"

    include_examples "sent email event objects are created"

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
          email_recipient_info: having_attributes(title: HearingEmailRecipient::RECIPIENT_TITLES[:appellant]),
          virtual_hearing: instance_of(VirtualHearing)
        }

        allow(HearingMailer).to receive(:confirmation).with(any_args).and_call_original
        allow(HearingMailer).to(
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

      include_examples "job is retried"
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

      include_examples "raises error", VirtualHearings::CreateConferenceJob::VirtualHearingNotCreatedError

      include_examples "job is retried"
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

      include_examples "raises error", VirtualHearings::CreateConferenceJob::VirtualHearingRequestCancelled

      include_examples "does not retry job"
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

          expect(EmailRecipientInfo).to(
            receive(:new)
              .with(instance_of(Hash))
              .twice
              .and_call_original
          )
          expect(EmailRecipientInfo).to(
            receive(:new)
              .with(
                hash_including(
                  name: FakeConstants.BGS_SERVICE.DEFAULT_POA_NAME,
                  title: HearingEmailRecipient::RECIPIENT_TITLES[:representative],
                  hearing_email_recipient: hearing.representative_recipient
                )
              )
              .once
              .and_call_original
          )

          subject.perform_now
        end
      end
    end

    context "when feature toggle is enabled" do
      before do
        FeatureToggle.enable!(:virtual_hearings_use_new_links)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:fetch).and_call_original
      end

      context "when all required env variables are set" do
        let(:expected_conference_id) { "0000001" }

        before do
          allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_PIN_KEY").and_return PIN_KEY
          allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_HOST").and_return URL_HOST
          allow(ENV).to receive(:[]).with("VIRTUAL_HEARING_URL_PATH").and_return URL_PATH
          allow(VirtualHearings::SequenceConferenceId).to receive(:next).and_return expected_conference_id
        end

        it "generates host and guest links", :aggregate_failures do
          subject.perform_now

          expected_alias_with_host = "BVA#{expected_conference_id}@#{URL_HOST}"
          expected_guest_pin = "7470125694"
          expected_host_pin = "3998472"
          expected_host_link = "https://#{URL_HOST}#{URL_PATH}/?conference=#{expected_alias_with_host}"\
            "&pin=#{expected_host_pin}&callType=video"
          expected_guest_link = "https://#{URL_HOST}#{URL_PATH}/?conference=#{expected_alias_with_host}"\
            "&pin=#{expected_guest_pin}&callType=video"

          virtual_hearing.reload
          expect(virtual_hearing.host_hearing_link).to eq(expected_host_link)
          expect(virtual_hearing.guest_hearing_link).to eq(expected_guest_link)
          expect(virtual_hearing.conference_id).to eq(nil)
          expect(virtual_hearing.status).to eq(:active)
          expect(virtual_hearing.alias_with_host).to eq(expected_alias_with_host)
          expect(virtual_hearing.host_pin_long).to eq(expected_host_pin)
          expect(virtual_hearing.guest_pin_long).to eq(expected_guest_pin)
          expect(virtual_hearing.all_emails_sent?).to eq(true)
        end

        include_examples "confirmation emails are sent"

        include_examples "sent email event objects are created"
      end

      context "when all required env variables are not set" do
        include_examples "raises error", VirtualHearings::CreateConferenceJob::VirtualHearingLinkGenerationFailed
        include_examples "does not retry job"
      end
    end
  end
end
