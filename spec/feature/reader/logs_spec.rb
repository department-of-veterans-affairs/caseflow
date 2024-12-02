# frozen_string_literal: true

require "selenium-webdriver"

RSpec.feature "Reader", :all_dbs do
  before do
    FeatureToggle.enable!(:pdf_page_render_time_in_ms)
    FeatureToggle.enable!(:metrics_monitoring)
    Fakes::Initializer.load!

    RequestStore[:current_user] = User.find_or_create_by(css_id: "BVASCASPER1", station_id: 101)
    Generators::VACOLS::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")

    User.authenticate!(roles: ["Reader"])
  end

  let(:file_number) { "123456789" }
  let(:ama_appeal) { Appeal.create(veteran_file_number: file_number) }
  let(:appeal) do
    Generators::LegacyAppealV2.create(
      documents: documents,
      case_issue_attrs: [
        { issdc: "1" },
        { issdc: "A" },
        { issdc: "3" },
        { issdc: "D" }
      ]
    )
  end

  let(:documents) do
    [
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago),
      Generators::Document.build(type: "Form 9", vbms_document_id: 4, received_at: 5.days.ago),
      Generators::Document.build(type: "NOD", received_at: 1.day.ago)
    ]
  end

  context "log Reader Metrics" do
    scenario "create a metric for pdf_page_render_time_in_ms" do
      expect(Metric.any?).to be false # There are no metrics
      Capybara.default_max_wait_time = 5 # seconds

      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"

      expect(page).to have_content("BOARD OF VETERANS' APPEALS")

      # Ensure that the correct metric was created
      metric = Metric.where(metric_message: "pdf_page_render_time_in_ms")&.last
      expect(metric).to be_present # New metric is created
      expect(metric.start).not_to be_nil
      expect(metric.end).not_to be_nil
      expect(metric.duration).to be > 0 # Confirm duration is not default 0 value

      # New checks for other metrics (start_time, end_time, duration)
      expect(metric.start).to be <= metric.end # Start time should be earlier or equal to end time
      expect(metric.end - metric.start).to be > 0 # Duration should be greater than 0
    end

    scenario "create and check multiple metrics related to PDF page render times" do
      expect(Metric.any?).to be false # Ensure no existing metrics

      # Trigger actions that generate metrics
      visit "/reader/appeal/#{appeal.vacols_id}/documents/1"
      visit "/reader/appeal/#{appeal.vacols_id}/documents/3"

      # Fetch the most recent metric related to render time
      metrics = Metric.where(metric_message: "pdf_page_render_time_in_ms").order(created_at: :desc)

      expect(metrics.count).to be >= 2 # At least two metrics should be created

      metrics.each do |metric|
        expect(metric.start).not_to be_nil
        expect(metric.end).not_to be_nil
        expect(metric.duration).to be > 0
        expect(metric.start).to be <= metric.end
        expect(metric.end - metric.start).to be > 0
      end
    end
  end
end
