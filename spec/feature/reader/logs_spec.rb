# frozen_string_literal: true

RSpec.feature "Reader", :all_dbs do
  before do
    Capybara.current_driver = :selenium_chrome
    FeatureToggle.enable!(:prefetch_disabled)
    FeatureToggle.enable!(:pdf_page_render_time_in_ms)
    FeatureToggle.enable!(:metrics_monitoring)
    Fakes::Initializer.load!

    RequestStore[:current_user] = User.find_or_create_by(css_id: "BVASCASPER1", station_id: 101)
    Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")

    User.authenticate!(roles: ["Reader"])
  end

  let(:documents) { [] }
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

  context "log Reader Metrics" do
    let(:documents) do
      [
        Generators::Document.create(
          filename: "My BVA Decision",
          type: "BVA Decision",
          received_at: 7.days.ago,
          vbms_document_id: 6,
          category_procedural: true,
          tags: [
            Generators::Tag.create(text: "New Tag1"),
            Generators::Tag.create(text: "New Tag2")
          ],
          description: Generators::Random.word_characters(50),
          file_number: file_number
        ),
        Generators::Document.create(
          filename: "My Form 9",
          type: "Form 9",
          received_at: 5.days.ago,
          vbms_document_id: 4,
          category_medical: true,
          category_other: true
        ),
        Generators::Document.create(
          filename: "My NOD",
          type: "NOD",
          received_at: 1.day.ago,
          vbms_document_id: 3
        )
      ]
    end

    scenario "create a metric for pdf_page_render_time_in_ms", js: true do
      expect(Metric.any?).to be false # There are no metrics
      # Set the maximum wait time for Capybara to wait for an element to appear
      Capybara.default_max_wait_time = 5 # seconds
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
      expect(page).to have_content("BOARD OF VETERANS' APPEALS")
      metric = Metric.where(metric_message: "pdf_page_render_time_in_ms")&.last
      expect(metric).to be_present # New metric is created
      expect(metric.start).not_to be_nil
      expect(metric.end).not_to be_nil
      expect(metric.duration).to be > 0 # Confirm duration not default 0 value
    end
  end
end
