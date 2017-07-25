require "rails_helper"

def scroll_position(element)
  page.evaluate_script("document.getElementById('#{element}').scrollTop")
end

def scroll_to(element, value)
  page.execute_script("document.getElementById('#{element}').scrollTop=#{value}")
end

def skip_because_sending_keys_to_body_does_not_work_on_travis
  if ENV["TRAVIS"]
    puts "Warning: skipping block because find('body').send_keys does not work on Travis"
  else
    yield
  end
end

def scroll_element_to_view(element)
  page.execute_script("document.getElementById('#{element}').scrollIntoView()")
end

def scroll_to_bottom(element)
  page.driver.evaluate_script <<-EOS
    function() {
      var elem = document.getElementById('#{element}');
      elem.scrollTop = elem.scrollHeight;
    }();
  EOS
end

# This utility function returns true if an element is currently visible on the page
def in_viewport(element)
  page.evaluate_script("document.getElementById('#{element}').getBoundingClientRect().top > 0" \
  " && document.getElementById('#{element}').getBoundingClientRect().top < window.innerHeight;")
end

def get_size(element)
  size = page.driver.evaluate_script <<-EOS
    function() {
      var ele = document.getElementById('#{element}');
      var rect = ele.getBoundingClientRect();
      return [rect.width, rect.height];
    }();
  EOS
  {
    width: size[0],
    height: size[1]
  }
end

def add_comment_without_clicking_save(text)
  # Add a comment
  click_on "button-AddComment"
  expect(page).to have_css(".cf-pdf-placing-comment")

  # pageContainer1 is the id pdfJS gives to the div holding the first page.
  find("#pageContainer1").click

  expect(page).to_not have_css(".cf-pdf-placing-comment")
  fill_in "addComment", with: text
end

def add_comment(text)
  add_comment_without_clicking_save(text)
  click_on "Save"
end

RSpec.feature "Reader" do
  before do
    FeatureToggle.disable!(:reader)
    FeatureToggle.enable!(:reader)

    Fakes::Initializer.load!
  end

  let(:vacols_record) { :remand_decided }

  let(:documents) { [] }

  let!(:issue_levels) do
    ["Other", "Left knee", "Right knee"]
  end

  let!(:issues) do
    [Generators::Issue.build(disposition: :allowed,
                             program: :compensation,
                             type: :elbow,
                             category: :service_connection,
                             levels: issue_levels
                            )
    ]
  end

  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents, issues: issues)
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
          vbms_document_id: 6,
          category_procedural: true
        ),
        Generators::Document.create(
          filename: "My Form 9",
          type: "Form 9",
          received_at: 5.days.ago,
          vbms_document_id: 5,
          category_medical: true,
          category_other: true
        ),
        Generators::Document.create(
          filename: "My NOD",
          type: "NOD",
          received_at: 1.day.ago,
          vbms_document_id: 4
        )
      ]
    end

    context "Welcome gate page" do
      let(:appeal2) do
        Generators::Appeal.build(vacols_record: vacols_record, documents: documents)
      end

      before do
        Fakes::CaseAssignmentRepository.appeal_records = [appeal, appeal2]
      end

      scenario "Enter a case" do
        visit "/reader/appeal"

        expect(page).to have_content(appeal.veteran_full_name)
        expect(page).to have_content(appeal.vbms_id)

        expect(page).to have_content(appeal.issues[0].description_label)
        expect(page).to have_content(appeal.issues[0].levels[0])
        expect(page).to have_content(appeal.issues[0].levels[1])
        expect(page).to have_content(appeal.issues[0].levels[2])

        expect(page).to have_title("Assignments | Caseflow Reader")

        click_on "New", match: :first

        expect(page).to have_current_path("/reader/appeal/#{appeal.vacols_id}/documents")
        expect(page).to have_content("Documents")

        # Test that the title changed. Functionality in PageRoute.jsx
        expect(page).to have_title("Claims Folder | Caseflow Reader")

        click_on "Caseflow Reader"
        expect(page).to have_current_path("/reader/appeal")
        expect(page).to have_title("Assignments | Caseflow Reader")

        click_on "Continue"

        expect(page).to have_content("Documents")
      end
    end

    scenario "Open document in new tab" do
      # Open the URL that the first document button points to. We cannot simply
      # click on the link since we've overridden the mouseup event to not open
      # the link, but instead to move to the document view in the SPA. Middle clicking
      # is not overridden, but I cannot figure out how to middle click in the test.
      # Instead we just visit the page specified by the link.
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      single_link = find_link(documents[0].type)[:href]
      visit single_link

      # Make sure there is document metadata, but no back button.
      expect(page).to have_content(documents[0].type)
      expect(page).to_not have_content("Back to all documents")

      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

      # Make sure the document link in the document view points to the same place
      # as the link we just tested.
      expect(find_link(documents[0].type)[:href]).to eq(single_link)
    end

    scenario "Progress indicator" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      click_on documents[0].type
      expect(find(".doc-list-progress-indicator")).to have_text("Document 3 of 3")
      click_on "Back to claims folder"
      fill_in "searchBar", with: "Form"
      click_on documents[1].type
      expect(find(".doc-list-progress-indicator")).to have_text("Document 1 of 1")
      expect(page).to have_selector(".doc-list-progress-indicator .filter-icon")
    end

    scenario "User visits help page" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      find('#menu-trigger').click
      find_link("Help").click
      expect(page).to have_content("Reader Help")
    end

    scenario "Clicking outside pdf or next pdf removes annotation mode" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
      add_comment_without_clicking_save("text")
      page.find("body").click
      expect(page).to_not have_css(".cf-pdf-placing-comment")
      add_comment_without_clicking_save("text")
      find("#button-next").click
      expect(page).to_not have_css(".cf-pdf-placing-comment")
    end

    scenario "Next and Previous buttons move between docs" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
      find("#button-next").click
      expect(find(".cf-document-type")).to have_text("BVA Decision")
      find("#button-previous").click
      find("#button-previous").click
      expect(find(".cf-document-type")).to have_text("NOD")
    end

    scenario "Arrow keys to navigate through documents" do
      def expect_doc_type_to_be(doc_type)
        expect(find(".cf-document-type")).to have_text(doc_type)
      end

      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"

      add_comment("comment text")
      click_on "Edit"
      find("#editCommentBox-1").send_keys(:arrow_left)
      expect_doc_type_to_be "Form 9"
      find("#editCommentBox-1").send_keys(:arrow_right)
      expect_doc_type_to_be "Form 9"

      click_on "Cancel"

      # The following lines work locally but not on Travis.
      # I spent two hours pushing changes and waiting 10
      # minutes to see if various changes would fix it.
      #
      # Please forgive me.
      skip_because_sending_keys_to_body_does_not_work_on_travis do
        find("body").send_keys(:arrow_right)
        expect_doc_type_to_be "BVA Decision"

        find("body").send_keys(:arrow_left)
        expect_doc_type_to_be "Form 9"
      end

      add_comment_without_clicking_save "unsaved comment text"
      find("#addComment").send_keys(:arrow_left)
      expect_doc_type_to_be "Form 9"
      find("#addComment").send_keys(:arrow_right)
      expect_doc_type_to_be "Form 9"

      fill_in "tags", with: "tag content"
      find("#tags").send_keys(:arrow_left)
      expect_doc_type_to_be "Form 9"
      find("#tags").send_keys(:arrow_right)
      expect_doc_type_to_be "Form 9"
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

      add_comment("Foo")

      # Expect comment to be visible on page
      expect(page).to have_content("Foo")

      # Expect comment to be in database
      annotation = documents[0].reload.annotations.first
      expect(annotation.comment).to eq("Foo")
      expect(annotation.user_id).to eq(current_user.id)

      # Edit the comment
      click_on "Edit"
      fill_in "editCommentBox-1", with: "FooBar"
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

      # Try to add an empty comment
      add_comment_without_clicking_save("")

      expect(find("#button-save")["disabled"]).to eq("true")

      # Try to edit a comment to contain no text
      add_comment("A")

      click_on "Edit"
      find("#editCommentBox-2").send_keys(:backspace)
      click_on "Save"

      # Delete modal should appear
      click_on "Confirm delete"

      # Comment should be removed
      expect(page).to_not have_css(".comment-container")
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
          ),
          Generators::Annotation.create(
            comment: "nice comment",
            document_id: documents[1].id,
            y: 300,
            page: 3
          )
        ]
      end

      scenario "Documents and Comments toggle button", focus: true do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on "Comments"
        expect(page).to have_content("another comment")
        expect(page).to have_content("how's it going")

        # A doc without a comment should not show up
        expect(page).not_to have_content(documents[2].type)

        # Filtering the document list should work in "Comments" mode.
        find("#categories-header svg").click
        find(".checkbox-wrapper-procedural").click
        expect(page).to have_content(documents[0].type)
        expect(page).not_to have_content(documents[1].type)

        click_on "Documents"
        expect(page).not_to have_content("another comment")
        expect(page).not_to have_content("how's it going")
      end

      def element_position(selector)
        page.driver.evaluate_script <<-EOS
          function() {
            var rect = document.querySelector('#{selector}').getBoundingClientRect();
            return {
              top: rect.top,
              left: rect.left
            };
          }();
        EOS
      end

      # :nocov:
      skip_because_sending_keys_to_body_does_not_work_on_travis do
        scenario "Leave annotation with keyboard" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
          assert_selector(".commentIcon-container", count: 5)
          find("body").send_keys [:alt, "c"]
          expect(page).to have_css(".cf-pdf-placing-comment")
          assert_selector(".commentIcon-container", count: 6)

          def placing_annotation_icon_position
            element_position "[data-placing-annotation-icon]"
          end

          orig_position = placing_annotation_icon_position

          KEYPRESS_ANNOTATION_MOVE_DISTANCE_PX = 5

          find("body").send_keys [:up]
          after_up_position = placing_annotation_icon_position
          expect(after_up_position["left"]).to eq(orig_position["left"])
          expect(after_up_position["top"]).to eq(orig_position["top"] - KEYPRESS_ANNOTATION_MOVE_DISTANCE_PX)

          find("body").send_keys [:down]
          after_down_position = placing_annotation_icon_position
          expect(after_down_position).to eq(orig_position)

          find("body").send_keys [:right]
          after_right_position = placing_annotation_icon_position
          expect(after_right_position["left"]).to eq(orig_position["left"] + KEYPRESS_ANNOTATION_MOVE_DISTANCE_PX)
          expect(after_right_position["top"]).to eq(orig_position["top"])

          find("body").send_keys [:left]
          after_left_position = placing_annotation_icon_position

          expect(after_left_position).to eq(orig_position)

          find("body").send_keys [:alt, :enter]
          expect(page).to_not have_css(".cf-pdf-placing-comment")
        end
      end
      # :nocov:

      scenario "Jump to section for a comment" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        annotation = documents[1].annotations[0]

        click_button("expand-#{documents[1].id}-comments-button")
        click_button("jumpToComment#{annotation.id}")

        # Wait for PDFJS to render the pages
        expect(page).to have_css(".page")
        comment_icon_id = "commentIcon-container-#{annotation.id}"

        # wait for comment annotations to load
        all(".commentIcon-container", wait: 3, count: 1)

        expect { in_viewport(comment_icon_id) }.to become_truthy
      end

      scenario "Scroll to comment" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[0].type

        element = "cf-sidebar-accordion"
        scroll_to(element, 0)

        # Wait for PDFJS to render the pages
        expect(page).to have_css(".page")

        # Click on the comment icon and ensure the scroll position of
        # the comment wrapper changes
        original_scroll = scroll_position(element)

        # Click on the second to last comment icon (last comment icon is off screen)
        all(".commentIcon-container", wait: 3, count: documents[0].annotations.size)[annotations.size - 3].click
        after_click_scroll = scroll_position(element)

        expect(after_click_scroll - original_scroll).to be > 0

        # Make sure the comment icon and comment are shown as selected
        expect(find(".comment-container-selected").text).to eq "baby metal 4 lyfe"

        id = "#{annotations[annotations.size - 3].id}-filter-1"

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

      scenario "Scrolling pages changes page numbers" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[1].type
        expect(page).to have_css(".page")
        scroll_element_to_view("pageContainer3")
        expect(find_field("page-progress-indicator-input").value).to eq "3"
      end

      scenario "Switch between pages to ensure rendering" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[1].type

        # Expect the 23 page to only be rendered once scrolled to.
        expect(find("#pageContainer23")).to_not have_content("Rating Decision")

        fill_in "page-progress-indicator-input", with: "23\n"

        expect(find("#pageContainer23")).to have_content("Rating Decision", wait: 4)

        expect(in_viewport("pageContainer23")).to be true
        expect(find_field("page-progress-indicator-input").value).to eq "23"

        # Entering invalid values leaves the viewer on the same page.
        fill_in "page-progress-indicator-input", with: "abcd\n"
        expect(in_viewport("pageContainer23")).to be true
        expect(find_field("page-progress-indicator-input").value).to eq "23"
      end
    end

    # this test being skipped because it often fails during the CI process
    # and it needs to be revaluated and fixed at a later time.
    # :nocov:
    scenario "Zooming changes the size of pages",
             skip: "This test sometimes fails because it cannot find the expected text" do
      scroll_amount = 500
      zoom_rate = 1.3

      # The margin of error we accept due to float arithmatic rounding
      size_margin_of_error = 5

      visit "/reader/appeal/#{appeal.vacols_id}/documents/3"

      # Wait for the page to load
      expect(page).to have_content("IN THE APPEAL")

      old_height_1 = get_size("pageContainer1")[:height]
      old_height_10 = get_size("pageContainer10")[:height]

      scroll_to("scrollWindow", scroll_amount)

      find("#button-zoomIn").click

      # Wait for the page to load
      expect(page).to have_content("IN THE APPEAL")

      # Rendered page is zoomed
      ratio = (get_size("pageContainer1")[:height] / old_height_1).round(1)
      expect(ratio).to eq(zoom_rate)

      # Non-rendered page is zoomed
      ratio = (get_size("pageContainer10")[:height] / old_height_10).round(1)
      expect(ratio).to eq(zoom_rate)

      # We should scroll further down since we zoomed but not further than the zoom rate
      # times how much we've scrolled.
      expect(scroll_position("scrollWindow")).to be_between(scroll_amount, scroll_amount * zoom_rate)

      # Zoom out to find text on the last page
      expect(page).to_not have_content("Office of the General Counsel (022D)")

      find("#button-zoomOut").click
      find("#button-zoomOut").click
      find("#button-zoomOut").click
      find("#button-zoomOut").click

      expect(page).to have_content("Office of the General Counsel (022D)")

      find("#button-fit").click

      # Fit to screen should make the height of the page the same as the height of the scroll window
      height_difference = get_size("pageContainer1")[:height].round - get_size("scrollWindow")[:height].round
      expect(height_difference.abs).to be < size_margin_of_error
    end
    # :nocov:

    scenario "Open single document view and open/close sidebar" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type

      # Expect only the first page of the pdf to be rendered
      find("#hide-menu-header").click
      expect(page).to_not have_content("Document Type")

      click_on "Open menu"
      expect(page).to have_content("Document Type")
    end

    scenario "Open and close accordion sidebar menu" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type

      def click_accordion_header(index)
        find_all(".rc-collapse-header")[index].click
      end

      click_accordion_header(0)
      expect(page).to_not have_content("Document Type")
      click_accordion_header(0)
      expect(page).to have_content("Document Type")

      click_accordion_header(1)
      expect(page).to_not have_content("Procedural")
      click_accordion_header(1)
      expect(page).to have_content("Procedural")

      click_accordion_header(2)
      expect(page).to_not have_content("Select or tag issue(s)")
      click_accordion_header(2)
      expect(page).to have_content("Select or tag issue(s)")

      click_accordion_header(3)
      expect(page).to_not have_content("Add a comment")
      click_accordion_header(3)
      expect(page).to have_content("Add a comment")
    end

    scenario "Open and close keyboard shortcuts modal" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type

      # Open modal
      click_on "View keyboard shortcuts"
      expect(page).to have_css(".cf-modal")
      expect(page).to have_content("Place a comment")

      # Close modal
      click_on "Thanks, got it!"
      expect(page).to_not have_css(".cf-modal")
    end

    scenario "Categories" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      def get_aria_labels(elems)
        elems.map do |elem|
          # I don't know why this is necessary, but it seems to trigger capybara to wait for the elements
          # to have content in the correct way. Without this, we'll sometimes see an empty list of elements,
          # but when we insert a quick sleep or inspect the browser, we see the full list. That means that
          # capybara is not waiting properly.
          elem["outerHTML"]

          elem["aria-label"]
        end
      end

      doc_0_categories =
        get_aria_labels all(".section--document-list table tr:first-child .cf-document-category-icons li")
      expect(doc_0_categories).to eq([])

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
      expect(doc_0_categories).to eq([])

      click_on documents[1].type

      expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Medical", "Other Evidence"])

      find("#button-next").click

      expect(find("#procedural", visible: false).checked?).to be false
      expect(find("#medical", visible: false).checked?).to be true
      expect(find("#other", visible: false).checked?).to be false
    end

    scenario "Tags" do
      TAG1 = "Medical".freeze
      TAG2 = "Law document".freeze

      DOC2_TAG1 = "Appeal Document".freeze

      SELECT_VALUE_LABEL_CLASS = ".Select-value-label".freeze

      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      click_on documents[0].type

      fill_in "tags", with: TAG1

      # making sure there is a dropdown showing up when text is entered
      expect(page).to have_css(".Select-menu-outer")

      # submit entering the tag
      fill_in "tags", with: (TAG1 + "\n")

      fill_in "tags", with: (TAG2 + "\n")

      # expecting the multi-selct to have the two new fields
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: TAG1)
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: TAG2)

      # adding new tags to 2nd document
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      click_on documents[1].type

      fill_in "tags", with: (DOC2_TAG1 + "\n")

      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: DOC2_TAG1)

      # getting remove buttons of all tags
      cancel_icons = page.all(".Select-value-icon", count: 1)

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
      expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 2)
    end

    scenario "Search and Filter" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      fill_in "searchBar", with: "BVA"

      expect(page).to have_content("BVA")
      expect(page).to_not have_content("Form 9")

      find(".cf-search-close-icon").click

      expect(page).to have_content("Form 9")

      expect(ClaimsFolderSearch.last).to have_attributes(
        user_id: current_user.id,
        appeal_id: appeal.id,
        query: "BVA"
      )
    end

    scenario "When user search term is not found" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      search_query = "does not exist in annotations"
      fill_in "searchBar", with: search_query

      expect(page).to have_content("Search results not found")
      expect(page).to have_content(search_query)
    end

    scenario "Download PDF file" do
      DownloadHelpers.clear_downloads
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      click_on documents[0].type
      filename = "#{documents[0].type}-#{documents[0].vbms_document_id}"
      find("#button-download").click
      DownloadHelpers.wait_for_download
      download = DownloadHelpers.downloaded?
      expect(download).to be_truthy
      expect(filename).to have_content("BVA Decision-6")
      DownloadHelpers.clear_downloads
    end
  end

  context "Large number of documents" do
    # This assumes that num_documents is enough to force the viewport to scroll.
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

    scenario "Open a document and return to list", skip: true do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      scroll_to_bottom("documents-table-body")
      original_scroll_position = scroll_position("documents-table-body")
      click_on documents.last.type

      click_on "Back to claims folder"

      expect(page).to have_content("#{num_documents} Documents")
      expect(in_viewport("read-indicator")).to be true
      expect(scroll_position("documents-table-body")).to eq(original_scroll_position)
    end

    scenario "Open the last document on the page and return to list" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents.last.id}"

      click_on "Back to claims folder"

      expect(page).to have_content("#{num_documents} Documents")

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
