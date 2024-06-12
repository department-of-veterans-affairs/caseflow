# frozen_string_literal: true

require "rails_helper"

RSpec.feature "Reader", :all_dbs do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:metrics_monitoring)
    FeatureToggle.enable!(:metrics_load_screen)
    FeatureToggle.enable!(:reader_get_document_logging)
    FeatureToggle.enable!(:metrics_get_pdfjs_doc)
    FeatureToggle.enable!(:pdf_page_render_time_in_ms)
    FeatureToggle.enable!(:metrics_reader_render_text)
    FeatureToggle.enable!(:metrics_pdf_store_pages)

    RequestStore[:current_user] = User.find_or_create_by(css_id: "BVASCASPER1", station_id: 101)
    Generators::Vacols::Staff.create(stafkey: "SCASPER1", sdomainid: "BVASCASPER1", slogid: "SCASPER1")

    User.authenticate!(roles: ["Reader"])
  end

  let(:appeal) do
    Generators::LegacyAppealV2.create(
      vacols_id: 111,
      documents: documents
    )
  end

  let(:metric_get_doc) { "Getting PDF document: \"/document/#{documents.first.id}/pdf\"" }
  let(:metric_get_pdfjs_doc) { "Storing PDF page" }
  let(:metric_render_time) { "PDFJS rendering text layer" }
  let(:metric_render_text) { "pdf_page_render_time_in_ms" }
  let(:metric_store_pages) { "Storing PDF page text" }

  context "Capture the 5 Reader Metrics for one page document" do
    let(:documents) do
      [
        Generators::Document.create(
          filename: "My NOD",
          type: "NOD",
          received_at: 1.day.ago,
          vbms_document_id: 3
        )
      ]
    end
    scenario "capture each metric once" do
      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_get_doc),
        anything
      ).exactly(:once)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_get_pdfjs_doc),
        anything
      ).exactly(:once)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_render_time),
        anything
      ).exactly(:once)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_render_text),
        anything
      ).exactly(:once)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_store_pages),
        anything
      ).exactly(:once)

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
    end
  end

  context "Capture the 5 Reader Metrics for two page document" do
    let(:documents) do
      [
        Generators::Document.create(
          filename: "My BVA Decision",
          type: "BVA Decision",
          received_at: 7.days.ago,
          vbms_document_id: 6
        )
      ]
    end
    scenario "capture 'Getting PDF document' metric once and other metrics twice (one for each page)" do
      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_get_doc),
        anything
      ).exactly(:once)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_get_pdfjs_doc),
        anything
      ).exactly(:twice)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_render_time),
        anything
      ).exactly(:twice)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_render_text),
        anything
      ).exactly(:twice)

      expect(Metric).to receive(:create_metric_from_rest).with(
        anything,
        hash_including(message: metric_store_pages),
        anything
      ).exactly(:twice)

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
    end
  end

  after(:each) do
    page.driver.quit
  end
end
