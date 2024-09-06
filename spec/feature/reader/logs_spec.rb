# frozen_string_literal: true

require "selenium-webdriver"

RSpec.feature "Reader", :all_dbs do
  before do
    FeatureToggle.enable!(:metrics_monitoring)
    Fakes::Initializer.load!

    RequestStore[:current_user] = User.find_or_create_by(css_id: "BVASCASPER1", station_id: 101)
    Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")

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

  describe "Log Reader Metrics" do
    context "Get Document Success" do
      it "creates a metric for getting PDF" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
        expect(page).to have_content("BOARD OF VETERANS' APPEALS")
        metric = Metric.where("metric_message LIKE ?", "Getting PDF%").first
        expect(metric.metric_type).to eq "performance"
      end
    end

    context "Get Document Error" do
      before do
        allow_any_instance_of(::DocumentController).to receive(:pdf) do
          large_document = "a" * (50 * 1024 * 1024) # 50MB document
          send_data large_document, type: "application/pdf", disposition: "inline"
        end
      end

      context "Internet Speed available", js: true do
        it "create an error Metric including internet speed" do
          FeatureToggle.enable!(:metrics_get_pdfjs_doc)
          Capybara.current_driver = :selenium_chrome_headless
          expect(Metric.any?).to be false
          visit "/reader/appeal/#{appeal.vacols_id}/documents/1"
          expect(page).to have_content("Unable to load document")
          metric = Metric.where("metric_message LIKE ?", "Getting PDF%").first
          expect(metric["metric_attributes"]["bandwidth"]).to end_with("Mbits/s")
          expect(metric.metric_attributes["step"]).to eq "getDocument"
          expect(metric.metric_type).to eq "error"
        end
      end
    end
  end
end
