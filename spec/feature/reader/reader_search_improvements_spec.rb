# frozen_string_literal: true

def clear_filters
  # When the "clear filters" button is clicked, the filtering message is reset,
  # and focus goes back on the Document toggle.
  find("#clear-filters").click
  expect(page.has_no_content?("Filtering by:")).to eq(true)
  expect(find("#button-documents")["class"]).to have_content("usa-button")
end

RSpec.feature "Reader", :all_dbs do
  before do
    FeatureToggle.enable!(:reader_search_improvements)
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

  feature "Document header filtering message" do
    background do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
    end

    it "clears all filters" do
      # category filter
      find("#categories-header .table-icon").click
      find(".checkbox-wrapper-procedural").click
      expect(page).to have_content("Categories (1)")

      # receipt date filter
      find(".receipt-date-column .unselected-filter-icon").click
      find(".date-filter-type-dropdown").click
      find("div", id: /react-select-2-option-\d/, text: "After this date").click
      fill_in("receipt-date-from", with: Date.current.strftime("%m/%d/%Y"))
      click_button("apply filter")
      expect(page).to have_content("Receipt Date (1)")

      # document type filter
      find(".doc-type-column .unselected-filter-icon").click
      find(:label, "NOD").click
      expect(page).to have_content("Document Types (1)")

      # tag filter
      find("#tags-header .table-icon").click
      tags_checkboxes = page.find("#tags-header").all(".cf-form-checkbox")
      tags_checkboxes[0].click
      expect(page).to have_content("Issue tags (1)")

      expect(page).to have_content("Filtering by:")
      clear_filters
    end

    context "filter by category" do
      it "displays the correct filtering message" do
        find("#categories-header .table-icon").click
        find(".checkbox-wrapper-procedural").click
        find(".checkbox-wrapper-medical").click

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Categories (2)")

        # deselect one filter
        find(".checkbox-wrapper-medical").click
        expect(page).to have_content("Categories (1)")

        # deselect all filters
        find(".checkbox-wrapper-procedural").click
        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end

      it "clears the category filter" do
        find("#categories-header .table-icon").click
        find(".checkbox-wrapper-procedural").click
        find(".checkbox-wrapper-medical").click

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Categories (2)")

        find(".cf-clear-filter-row .cf-text-button").click

        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end
    end

    context "filter by receipt date" do
      it "displays the correct filtering message" do
        # find and fill in date filter with today's date
        find(".receipt-date-column .unselected-filter-icon").click
        find(".date-filter-type-dropdown").click
        find("div", id: /react-select-2-option-\d/, text: "After this date").click
        fill_in("receipt-date-from", with: Date.current.strftime("%m/%d/%Y"))
        click_button("apply filter")

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Receipt Date (1)")

        clear_filters
      end

      it "clears the receipt date filter using 'clear all filters'" do
        # find and fill in date filter with today's date
        find(".receipt-date-column .unselected-filter-icon").click
        find(".date-filter-type-dropdown").click
        find("div", id: /react-select-2-option-\d/, text: "After this date").click
        fill_in("receipt-date-from", with: Date.current.strftime("%m/%d/%Y"))
        click_button("apply filter")

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Receipt Date (1)")

        # test "clear all filters" button
        click_on "Clear all filters"
        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end

      it "clears the receipt date filter by using receipt date clear filter button" do
        # find and fill in date filter with today's date
        find(".receipt-date-column .unselected-filter-icon").click
        find(".date-filter-type-dropdown").click
        find("div", id: /react-select-2-option-\d/, text: "After this date").click
        fill_in("receipt-date-from", with: Date.current.strftime("%m/%d/%Y"))
        click_button("apply filter")

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Receipt Date (1)")

        # test "clear receipt date filter" button
        find(".receipt-date-column .unselected-filter-icon").click
        click_on "Clear Receipt Date filter"
        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end
    end

    context "filter by document type" do
      it "displays the correct filtering message" do
        find(".doc-type-column .unselected-filter-icon").click
        find(:label, "NOD").click
        find(:label, "Form 9").click

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Document Types (2)")

        # deselect one filter
        find(:label, "NOD").click
        expect(page).to have_content("Document Types (1)")

        # deselect all filters
        find(:label, "Form 9").click
        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end

      it "clears the document type filter" do
        find(".doc-type-column .unselected-filter-icon").click
        find(:label, "NOD").click
        find(:label, "Form 9").click

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Document Types (2)")

        # test "clear document type filter" button
        find(".cf-clear-filter-row .cf-text-button").click
        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end

      it "searches available document type filters" do
        find(".doc-type-column .unselected-filter-icon").click
        find(".cf-dropdown-filter .cf-search-input-with-close").fill_in(with: "nod")

        expect(find(".cf-dropdown-filter ul")).to have_selector("li", count: 1)

        find(:label, "NOD").click
        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Document Types (1)")

        clear_filters
      end
    end

    context "filter by issue tag" do
      it "displays the correct filtering message" do
        # filter by tag
        find("#tags-header .table-icon").click
        tags_checkboxes = page.find("#tags-header").all(".cf-form-checkbox")
        tags_checkboxes[0].click
        tags_checkboxes[1].click
        expect(page).to have_content("Issue tags (2)")

        # deselect one filter
        tags_checkboxes[0].click
        expect(page).to have_content("Issue tags (1)")

        # deselect all filters
        tags_checkboxes[1].click
        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end

      it "clears the issue tag filter" do
        # filter by tag
        find("#tags-header .table-icon").click
        tags_checkboxes = page.find("#tags-header").all(".cf-form-checkbox")
        tags_checkboxes[0].click
        tags_checkboxes[1].click

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Issue tags (2)")

        find(".cf-clear-filter-row .cf-text-button").click

        expect(page.has_no_content?("Filtering by:")).to eq(true)
      end

      it "searches available issue tag filters" do
        find("#tags-header .table-icon").click
        find(".cf-dropdown-filter .cf-search-input-with-close").fill_in(with: "tag1")

        expect(find(".cf-dropdown-filter ul")).to have_selector("li", count: 1)

        find(:label, "New Tag1").click
        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Issue tags (1)")

        clear_filters
      end
    end

    context "filter by comments" do
      it "displays the correct filtering message" do
        # filter by comments
        click_on "Comments"
        expect(page).to have_content("Sorted by relevant date")

        click_on "Documents"
        # category filter is only visible when DocumentsTable displayed, but affects Comments
        find("#categories-header .table-icon").click
        find(".checkbox-wrapper-procedural").click

        click_on "Comments"
        expect(page).to have_content("Sorted by relevant date")

        clear_filters
      end
    end
  end
end
