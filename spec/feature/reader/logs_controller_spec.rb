# frozen_string_literal: true

RSpec.feature 'Metrics::V2::LogsController', type: :feature do
  before do
    FeatureToggle.enable!(:metrics_monitoring)
    FeatureToggle.enable!(:prefetch_disabled)
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

  context "pdf_page_render_time_in_ms Feature toggle enabled" do
    scenario "create a metric for pdf_page_render_time_in_ms" do
      FeatureToggle.enable!(:metrics_get_pdfjs_doc)
      expect(Metric.any?).to be false # There are no metrics
      Capybara.default_max_wait_time = 5 # seconds

      allow_any_instance_of(DocumentController).to receive(:pdf) do |controller|

        original_response = controller.send_file(
          documents[1].serve,
          type: "application/pdf"
        )
        # Simulating the response from EFolder v2 documents API
        document_source = { "X-Document-Source" => "S3" }
        controller.response.headers.merge!(document_source)

        original_response
      end

      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"

      expect(page).to have_content("BOARD OF VETERANS' APPEALS")
      metric = Metric.where("metric_message LIKE ?", "%/document/2/pdf%").first
      expect(metric).to be_present # New metric is created
      expect(metric.additional_info).not_to be_nil
      expect(metric.additional_info.keys).to include("source")
      expect(metric.duration).to be > 0 # Confirm duration not default 0 value
    end
  end
end
