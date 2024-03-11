# frozen_string_literal: true

def nil_in_db(metric_msg)
  db_result = Metric.where(metric_message: metric_msg)&.last
  expect(db_result).to be_nil
end

def exists_in_db(metric_msg)
  db_result = Metric.where(metric_message: metric_msg)
  expect(db_result.count).to eq(1)
end

def scroll_event(pos_x, pos_y)
  page.find(".ReactVirtualized__Grid").scroll_to(pos_x, pos_y)
  sleep 5
end

RSpec.feature "Reader", :all_dbs, type: :feature do
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

  after(:each) do
    page.driver.quit
  end

  let(:appeal) do
    Generators::LegacyAppealV2.create(
      vacols_id: 111,
      documents: documents
    )
  end

  let(:metric_get_pdf_doc) { "Getting PDF document: \"/document/#{documents.first.id}/pdf\"" }
  let(:metric_store_pdf_page) { "Storing PDF page #{page_number}" }
  let(:metric_store_pdf_page_text) { "Storing PDF page #{page_number} text" }
  let(:metric_render_pdf_page_text) { "Rendering PDF page #{page_number} text" }
  let(:metric_render_pdf_page_time) { "pdf_page_render_time_in_ms" }

  context "Capture the 5 Reader Metrics for one page document" do
    let(:page_number) { 1 }
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
      nil_in_db(metric_get_pdf_doc)
      nil_in_db(metric_render_pdf_page_time)
      nil_in_db(metric_store_pdf_page)
      nil_in_db(metric_store_pdf_page_text)
      nil_in_db(metric_render_pdf_page_text)

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
      sleep 5

      exists_in_db(metric_get_pdf_doc)
      exists_in_db(metric_render_pdf_page_time)
      exists_in_db(metric_store_pdf_page)
      exists_in_db(metric_store_pdf_page_text)
      exists_in_db(metric_render_pdf_page_text)

      event_id = Metric.where(metric_message: metric_render_pdf_page_time).last.event_id
      expect(Metric.where(event_id: event_id).count).to eq(5)
    end
  end

  context "Capture the 5 Reader Metrics for two page document" do
    let(:page_number) { 2 }
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

    scenario "capture 'Getting PDF document' and 'pdf_page_render_time_in_ms' metrics once and other metrics twice (one for each page)" do
      nil_in_db(metric_get_pdf_doc)
      nil_in_db(metric_render_pdf_page_time)
      nil_in_db(metric_store_pdf_page)
      nil_in_db(metric_store_pdf_page_text)
      nil_in_db(metric_render_pdf_page_text)

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
      sleep 5

      exists_in_db(metric_get_pdf_doc)
      exists_in_db(metric_render_pdf_page_time)
      exists_in_db(metric_store_pdf_page)
      exists_in_db(metric_store_pdf_page_text)
      exists_in_db(metric_render_pdf_page_text)

      event_id = Metric.where(metric_message: metric_render_pdf_page_time).last.event_id
      expect(Metric.where(event_id: event_id).count).to eq(8)
    end
  end

  context "Capture scroll event metric" do
    let(:documents) do
      [
        Generators::Document.create(
          filename: "My Form 9",
          type: "Form 9",
          received_at: 5.days.ago,
          vbms_document_id: 4
        )
      ]
    end

    scenario "scroll metric recorded when user scrolls vertically" do
      metric_scroll = "Scroll to position 0, 500"
      nil_in_db(metric_scroll)

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

      scroll_event(0, 500)
      exists_in_db(metric_scroll)

      scroll_event(0, 0)
      db_result = Metric.where("metric_message LIKE ?", "Scroll to position%")
      expect(db_result.count).to eq(2)
    end

    scenario "scroll metric recorded when user scrolls horizontally" do
      metric_scroll = "Scroll to position 5, 0"
      nil_in_db(metric_scroll)

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
      page.find("#button-zoomIn").click
      page.find("#button-zoomIn").click
      sleep 5

      scroll_event(5, 0)
      exists_in_db(metric_scroll)

      event_id = Metric.where(metric_message: metric_render_pdf_page_time).last.event_id
      scroll_event_id = Metric.where(metric_message: metric_scroll).last.event_id
      expect(event_id).to eql(scroll_event_id)
    end

    scenario "capture scroll event metric when user scrolls 5 times" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

      scroll_event(0, 50)
      scroll_event(0, 10)
      scroll_event(0, 0)
      page.find("#button-zoomIn").click
      page.find("#button-zoomIn").click
      sleep 5
      scroll_event(10, 50)
      scroll_event(0, 110)

      db_result = Metric.where("metric_message LIKE ?", "Scroll to position%")
      expect(db_result.count).to eq(5)
    end
  end
end
