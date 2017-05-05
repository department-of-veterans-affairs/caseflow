require "rails_helper"

def scroll_position(element)
  page.evaluate_script("document.getElementById('#{element}').scrollTop")
end

def scroll_to(element, value)
  page.execute_script("document.getElementById('#{element}').scrollTop=#{value}")
end

# This utility function returns true if an element is currently visible on the page
def in_viewport(element)
  page.evaluate_script("document.getElementById('#{element}').getBoundingClientRect().top > 0" \
  " && document.getElementById('#{element}').getBoundingClientRect().top < window.innerHeight;")
end

RSpec.feature "Reader" do
  before do
    FeatureToggle.disable!(:reader)
    FeatureToggle.enable!(:reader)
  end

  let(:vacols_record) { :remand_decided }

  let(:documents) { [] }
  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Reader"])
  end

  context "Short list of documents" do
    # Currently the vbms_document_ids need to be set since they correspond to specific
    # files to load when we fetch content.
    let(:documents) do
      [
        Generators::Document.create(
          filename: "My BVA Decision",
          type: "BVA Decision",
          received_at: 7.days.ago,
          vbms_document_id: 5,
          category_procedural: true
        ),
        Generators::Document.create(
          filename: "My Form 9",
          type: "Form 9",
          received_at: 5.days.ago,
          vbms_document_id: 2,
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

    scenario "PdfListView Dropdown" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      def expect_dropdown_filter_to_be_hidden
        expect(all(".cf-dropdown-filter")).to be_empty
      end

      def expect_dropdown_filter_to_be_visible
        expect(all(".cf-dropdown-filter").count).to eq(1)
      end

      expect_dropdown_filter_to_be_hidden

      find("#categories-header .table-icon").click
      expect_dropdown_filter_to_be_visible

      find(".checkbox-wrapper-procedural").click
      expect(find("#procedural", visible: false).checked?).to be true

      expect(page).to have_content("Showing limited results")

      find("#receipt-date-header").click
      expect_dropdown_filter_to_be_hidden

      find("#categories-header .table-icon").click
      expect_dropdown_filter_to_be_visible

      expect(find("#procedural", visible: false).checked?).to be true

      find("#categories-header .table-icon").send_keys :enter
      expect_dropdown_filter_to_be_hidden

      find("#clear-filters").click

      find("#categories-header .table-icon").send_keys :enter
      expect_dropdown_filter_to_be_visible

      expect(find("#procedural", visible: false).checked?).to be false
    end

    scenario "Add comment" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Caseflow Reader")

      # Click on the link to the first file
      click_on documents[0].type

      # Ensure PDF content loads (using :all because the text is hidden)
      expect(page).to have_content(:all, "Important Decision Document!!!")

      # Add a comment
      click_on "button-AddComment"
      expect(page).to have_css(".cf-pdf-placing-comment")

      # pageContainer1 is the id pdfJS gives to the div holding the first page.
      find("#pageContainer1").click

      expect(page).to_not have_css(".cf-pdf-placing-comment")
      fill_in "addComment", with: "Foo"
      click_on "Save"

      # Expect comment to be visible on page
      expect(page).to have_content("Foo")

      # Expect comment to be in database
      annotation = documents[0].reload.annotations.first
      expect(annotation.comment).to eq("Foo")
      expect(annotation.user_id).to eq(current_user.id)

      # Edit the comment
      click_on "Edit"
      fill_in "editCommentBox", with: "FooBar"
      click_on "Save"

      # Expect edited comment to be visible on opage
      expect(page).to have_content("FooBar")

      # Expect comment to be in database
      expect(documents[0].reload.annotations.first.comment).to eq("FooBar")

      # Delete the comment
      click_on "Delete"

      # Confirm the delete
      click_on "Confirm delete"

      # Expect the comment to be removed from the page
      expect(page).to_not have_content("FooBar")

      # Expect the comment to be removed from the database
      expect(documents[0].reload.annotations.count).to eq(0)
    end

    context "When there is an existing annotation" do
      let!(:annotations) do
        [
          Generators::Annotation.create(
            comment: "another comment",
            document_id: documents[0].id,
            y: 150
          ),
          Generators::Annotation.create(
            comment: "how's it going",
            document_id: documents[0].id,
            y: 200
          ),
          Generators::Annotation.create(
            comment: "my mother is a fish",
            document_id: documents[0].id,
            y: 250
          ),
          Generators::Annotation.create(
            comment: "baby metal 4 lyfe",
            document_id: documents[0].id,
            y: 300
          ),
          Generators::Annotation.create(
            comment: "hello world",
            document_id: documents[0].id,
            y: 750
          )
        ]
      end

      scenario "Expand All button" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on "Expand all"
        expect(page).to have_content("another comment")
        expect(page).to have_content("how's it going")
        click_button("expand-#{documents[0].id}-comments-button")

        # when a comment is closed, the button is changed to expand all
        expect(page).to have_button("Expand all")

        click_button("expand-#{documents[0].id}-comments-button")

        # when that comment is reopened, the button is changed to collapse all
        click_on "Collapse all"
        expect(page).not_to have_content("another comment")
        expect(page).not_to have_content("how's it going")
      end

      scenario "Scroll to comment" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[0].type

        element = "cf-comment-wrapper"
        scroll_to(element, 0)

        # Wait for PDFJS to render the pages
        expect(page).to have_css(".page")

        # Click on the comment icon and ensure the scroll position of
        # the comment wrapper changes
        original_scroll = scroll_position(element)

        # Click on the second to last comment icon (last comment icon is off screen)
        all(".commentIcon-container", wait: 3, count: annotations.size)[annotations.size - 2].click
        after_click_scroll = scroll_position(element)

        expect(after_click_scroll - original_scroll).to be > 0

        # Make sure the comment icon and comment are shown as selected
        expect(page).to have_css(".comment-container-selected")

        id = "#{annotations[annotations.size - 2].id}-filter-1"

        # This filter is the blue highlight around the comment icon
        find("g[filter=\"url(##{id})\"]")
      end

      scenario "Scroll to comment icon" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[0].type

        expect(page).to have_content(annotations[0].comment)

        # Wait for PDFJS to render the pages
        expect(page).to have_css(".page")

        # Click on the comment and ensure the scroll position changes
        # by the y value the comment.
        element = "scrollWindow"
        original_scroll = scroll_position(element)

        # Click on the off screen comment (0 through 3 are on screen)
        find("#comment4").click
        after_click_scroll = scroll_position(element)

        expect(after_click_scroll - original_scroll).to be > 0

        # Make sure the comment icon and comment are shown as selected
        expect(page).to have_css(".comment-container-selected")
        id = "#{annotations[4].id}-filter-1"

        # This filter is the blue highlight around the comment icon
        find("g[filter=\"url(##{id})\"]")
      end
    end

    scenario "Scrolling renders pages" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      click_on documents[0].type
      expect(page).to have_css(".page")

      # Expect only the first page to be reneder on first load
      # But if we scroll second page should be rendered and
      # we should be able to find text from the second page.
      expect(page).to_not have_content("Banana. Banana who")
      scroll_to("scrollWindow", 500)
      expect(page).to have_content("Banana. Banana who", wait: 3)
    end

    scenario "Open single document view and open/close sidebar" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type

      # Expect only the first page of the pdf to be rendered
      find("#button-hide-menu").click
      expect(page).to_not have_content("Document Type")

      click_on "Open menu"
      expect(page).to have_content("Document Type")
    end

    scenario "Categories" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      def get_aria_labels(elems)
        elems.map do |elem|
          elem["aria-label"]
        end
      end

      doc_0_categories =
        get_aria_labels all(".section--document-list table tr:first-child .cf-document-category-icons li")
      expect(doc_0_categories).to eq(["Procedural"])

      doc_1_categories =
        get_aria_labels all(".section--document-list table tr:nth-child(2) .cf-document-category-icons li")
      expect(doc_1_categories).to eq(["Medical", "Other Evidence"])

      click_on documents[0].type

      expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Procedural"])

      find(".checkbox-wrapper-procedural").click
      find(".checkbox-wrapper-medical").click

      expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Medical"])

      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      doc_0_categories =
        get_aria_labels all(".section--document-list table tr:first-child .cf-document-category-icons li")
      expect(doc_0_categories).to eq(["Medical"])

      click_on documents[1].type

      expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Medical", "Other Evidence"])

      find("#button-next").click

      expect(find("#procedural", visible: false).checked?).to be false
      expect(find("#medical", visible: false).checked?).to be false
      expect(find("#other", visible: false).checked?).to be false
    end

    scenario "Tags" do
      TAG1 = "Medical".freeze
      TAG2 = "Law document".freeze

      DOC2_TAG1 = "Appeal Document".freeze

      SELECT_VALUE_LABEL_CLASS = ".Select-value-label".freeze

      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      click_on documents[0].type

      input_element = find(".Select-input > input")
      input_element.click.native.send_keys(TAG1)

      # making sure there is a dropdown showing up when text is entered
      expect(page).to have_css(".Select-menu-outer")

      # submit entering the tag
      input_element.send_keys(:enter)

      find(".Select-input > input").click.native.send_keys(TAG2, :enter)

      # expecting the multi-selct to have the two new fields
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: TAG1)
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: TAG2)

      # adding new tags to 2nd document
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      click_on documents[1].type
      find(".Select-control").click
      input_element = find(".Select-input > input")
      input_element.click.native.send_keys(DOC2_TAG1, :enter)

      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: DOC2_TAG1)
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 3)

      # getting remove buttons of all tags
      cancel_icons = page.all(".Select-value-icon", count: 3)

      # rubocop:disable all
      # delete all tags
      for i in (cancel_icons.length - 1).downto(0)
        cancel_icons[i].click
      end
      # rubocop:enable all

      # expecting the page not to have any tags
      expect(page).not_to have_css(SELECT_VALUE_LABEL_CLASS, text: DOC2_TAG1)
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 0)

      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      click_on documents[0].type

      # verify that the tags on the previous document still exist
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 4)
    end

    scenario "Search and Filter" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      fill_in "searchBar", with: "BVA"

      expect(page).to have_content("BVA")
      expect(page).to_not have_content("Form 9")

      find(".cf-search-close-icon").click

      expect(page).to have_content("Form 9")
    end
  end

  context "Large number of documents" do
    let(:num_documents) { 20 }
    let(:documents) do
      (1..num_documents).to_a.reduce([]) do |acc, number|
        acc << Generators::Document.create(
          filename: number.to_s,
          type: "BVA Decision #{number}",
          received_at: number.days.ago,
          vbms_document_id: number,
          category_procedural: true
        )
      end
    end

    scenario "Open a document and return to list" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      # Click on the document at the top
      click_on documents.last.type

      click_on "Back to all documents"

      expect(page).to have_content("#{num_documents} Documents")

      # Make sure the document is scrolled
      expect(in_viewport("read-indicator")).to be true
    end
  end

  context "When user is not whitelisted" do
    before do
      FeatureToggle.enable!(:reader, users: ["FAKE_CSS_ID"])
    end

    scenario "it redirects to unauthorized" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Unauthorized")
    end
  end
end
