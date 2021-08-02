# frozen_string_literal: true

describe ETLBuilderJob, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  context "when error occurs" do
    subject { job.perform_now }
    let(:job) { described_class.new }
    let(:slack_service) { SlackService.new(url: "http://www.example.com") }

    before do
      allow(job).to receive(:sweep_etl) { fail StandardError, "oops!" }

      allow(SlackService).to receive(:new).and_return(slack_service)
      allow(slack_service).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }

      allow(Raven).to receive(:capture_exception) { @raven_called = true }
      allow(Raven).to receive(:last_event_id) { @raven_called && "sentry_12345" }
    end

    it "sends alert to Sentry and Slack" do
      subject

      expect(slack_service).to have_received(:send_notification).with(
        "Error running ETLBuilderJob. See Sentry event sentry_12345",
        "ETLBuilderJob",
        "#appeals-data-workgroup"
      )
      expect(@raven_called).to eq(true)
    end
  end

  describe "perform" do
    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job",
        metric_group: "etl_builder_job",
        metric_name: "runtime",
        metric_value: anything
      )
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job_segment",
        metric_group: "etl_builder",
        metric_name: "runtime",
        metric_value: anything
      )
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job_segment",
        metric_group: "etl_sweeper",
        metric_name: "runtime",
        metric_value: anything
      )
      ETL::Builder.syncer_klasses.each { |klass| expect(klass.target_class.all.count).to eq(0) }
    end

    subject { described_class.perform_now }

    context "when nothing has changed" do
      before do
        ETL::Builder.new.full
      end

      it "sends alert to Slack" do
        Timecop.travel(Time.zone.now + 1.hour) { subject }

        expect(@slack_msg).to eq "[WARN] ETL failed to sync any records"
      end
    end

    context "when multiple records have changed" do
      it "silently succeeds" do
        Timecop.travel(1.hour.ago) { subject }

        expect(@slack_msg).to be_nil
      end
    end

    context "when one deleted row is swept up" do
      before do
        ETL::Builder.new.full
        Appeal.last.delete
        Appeal.last.touch
      end

      it "does not send INFO message to slack" do
        Timecop.travel(1.hour.ago) { subject }

        expect(@slack_msg).to be_nil
      end

      context "when more than 20 rows swept up" do
        before do
          20.times { create(:appeal) }
          ETL::Builder.new.full
          Appeal.delete_all
          create(:appeal)
        end

        it "sends INFO message to slack" do
          Timecop.travel(1.hour.ago) { subject }

          expect(@slack_msg).to match(/\[INFO\] ETL swept up \d+ deleted records/)
        end
      end
    end
  end
end
