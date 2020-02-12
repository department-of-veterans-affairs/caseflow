# frozen_string_literal: true

describe ETLBuilderJob, :etl, :all_dbs do
  include SQLHelpers

  include_context "AMA Tableau SQL"

  describe "perform" do
    before do
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| @slack_msg = first_arg }
      expect(DataDogService).to receive(:emit_gauge).with(
        app_name: "caseflow_job",
        metric_group: "etl_builder_job",
        metric_name: "runtime",
        metric_value: anything
      )
      ETL::Builder::ETL_KLASSES.each { |klass| expect("ETL::#{klass}".constantize.all.count).to eq(0) }
    end

    subject { described_class.perform_now }

    context "when nothing has changed" do
      it "sends alert to Slack" do
        Timecop.travel(Time.zone.now + 1.hour) { subject }

        expect(@slack_msg).to eq "ETL failed to sync any records"
      end
    end

    context "when multiple records have changed" do
      it "silently succeeds" do
        Timecop.travel(1.hour.ago) { subject }

        expect(@slack_msg).to be_nil
      end
    end
  end
end
