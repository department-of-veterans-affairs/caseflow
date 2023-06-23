# frozen_string_literal: true

def scrolled_amount(child_class_name)
  page.evaluate_script <<-EOS
    function() {
      var list = document.getElementsByClassName('#{child_class_name}');

      for (elem of list) {
        if (elem.style.visibility == "visible") {
          return elem.parentElement.scrollTop;
        }
      }

      return 0;
    }();
  EOS
end

def add_comment_without_clicking_save(text)
  # It seems that this can fail in some cases on Travis, retry if it does.
  3.times do
    # Add a comment
    click_on "button-AddComment"
    expect(page).to have_css(".canvas-cursor", visible: true)

    # text-${pageIndex} is the id of the first page's CommentLayer
    page.execute_script("document.querySelectorAll('[id^=\"comment-layer-0\"]')[0].click()")

    expect(page).to_not have_css(".canvas-cursor")

    begin
      find("#addComment")
      break
    rescue Capybara::ElementNotFound
      Rails.logger.info("#addComment not found, trying again")
    end
  end
  fill_in "addComment", with: text, wait: 10
end

def add_comment(text)
  add_comment_without_clicking_save(text)
  click_on "Save"
end

RSpec.feature "Reader", :all_dbs do
  before do
    FeatureToggle.enable!(:interface_version_2)
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

    feature "Document header filtering message" do
      background do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"
      end

      it "can filter by categories, tags, and comments" do
        # filter by category
        find("#categories-header .table-icon").click
        find(".checkbox-wrapper-procedural").click
        find(".checkbox-wrapper-medical").click

        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Categories (2)")

        # deselect medical filter
        find(".checkbox-wrapper-medical").click
        expect(page).to have_content("Categories (1)")
        find("#clear-filters").click

        # filter by tag
        find("#tags-header .table-icon").click
        tags_checkboxes = page.find("#tags-header").all(".cf-form-checkbox")
        tags_checkboxes[0].click
        tags_checkboxes[1].click
        expect(page).to have_content("Issue tags (2)")

        # unchecking tag filters
        tags_checkboxes[0].click
        expect(page).to have_content("Issue tags (1)")

        tags_checkboxes[1].click
        expect(page).to_not have_content("Issue tags")

        # filter by comments
        click_on "Comments"
        expect(page).to have_content("Sorted by relevant date")

        click_on "Documents"
        # category filter is only visible when DocumentsTable displayed, but affects Comments
        find("#categories-header .table-icon").click
        find(".checkbox-wrapper-procedural").click

        click_on "Comments"
        expect(page).to have_content("Sorted by relevant date")

        # When the "clear filters" button is clicked, the filtering message is reset,
        # and focus goes back on the Document toggle.
        find("#clear-filters").click
        expect(page.has_no_content?("Filtering by:")).to eq(true)
        expect(find("#button-documents")["class"]).to have_content("usa-button")
      end
    end

    context "Appeals without any issues" do
      let(:fetched_at_format) { "%D %l:%M%P %Z" }
      let(:vbms_fetched_ts) { Time.zone.now }
      let(:vva_fetched_ts) { Time.zone.now }

      let(:vbms_ts_string) { "Last VBMS retrieval: #{vbms_fetched_ts.strftime(fetched_at_format)}".squeeze(" ") }
      let(:vva_ts_string) { "Last VVA retrieval: #{vva_fetched_ts.strftime(fetched_at_format)}".squeeze(" ") }

      let(:appeal) do
        Generators::LegacyAppealV2.build(
          documents: documents,
          manifest_vbms_fetched_at: vbms_fetched_ts,
          manifest_vva_fetched_at: vva_fetched_ts,
          case_issue_attrs: []
        )
      end

      scenario "Claims folder details issues and pdf view sidebar show no issues message" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"
        find(".rc-collapse-header", text: "Claims folder details").click
        expect(page).to have_css("#claims-folder-issues", text: "No issues on appeal")

        visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
        find("h3", text: "Document information").click
        expect(find(".cf-sidebar-document-information")).to have_text("No issues on appeal")
      end

      context "When both document source manifest retrieval times are set" do
        scenario "Both times display on the page and there are no document alerts" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents"
          expect(find("#vbms-manifest-retrieved-at").text).to have_content(vbms_ts_string)
          expect(find("#vva-manifest-retrieved-at").text).to have_content(vva_ts_string)
          expect(page).to_not have_css(".section--document-list .usa-alert")
        end
      end

      context "When VVA manifest retrieval time is older, but within the eFolder cache limit" do
        let(:vva_fetched_ts) { Time.zone.now - 2.hours }
        scenario "Both times display on the page and there are no document alerts" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents"
          expect(find("#vbms-manifest-retrieved-at").text).to have_content(vbms_ts_string)
          expect(find("#vva-manifest-retrieved-at").text).to have_content(vva_ts_string)
          expect(page).to_not have_css(".section--document-list .usa-alert")
        end
      end

      context "When VVA manifest retrieval time is olde and outside of the eFolder cache limit" do
        let(:vva_fetched_ts) { Time.zone.now - 4.hours }
        scenario "Both times display on the page and a warning alert is shown" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents"
          expect(find("#vbms-manifest-retrieved-at").text).to have_content(vbms_ts_string)
          expect(find("#vva-manifest-retrieved-at").text).to have_content(vva_ts_string)
          expect(find(".section--document-list .usa-alert-warning").text).to have_content("4 hours ago")
        end
      end

      context "When VVA manifest retrieval time is nil" do
        let(:vva_fetched_ts) { nil }
        scenario "Only VBMS time displays on the page and error alert is shown" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents"
          expect(find("#vbms-manifest-retrieved-at").text).to have_content(vbms_ts_string)
          expect(page).to_not have_css("#vva-manifest-retrieved-at")
          expect(page).to have_css(".section--document-list .usa-alert-error")
        end
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
      click_on "Back"
      fill_in "searchBar", with: "Form"
      click_on documents[1].type
      expect(find(".doc-list-progress-indicator")).to have_text("Document 1 of 1")
      expect(page).to have_selector(".doc-list-progress-indicator .filter-icon")
    end

    scenario "User visits help page" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      find("a", text: "DSUSER (DSUSER)").click
      find_link("Help").click
      expect(page).to have_content("Reader Help")
    end

    context "Query params in documents URL" do
      scenario "User enters valid category" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents?category=case_summary"
        expect(page).to have_content("Filtering by:")
        expect(page).to have_content("Categories (1)")
      end

      scenario "User enters invalid category" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents?category=thisisfake"
        expect(page).to_not have_content("Filtering by:")
        expect(page).to_not have_content("Categories (1)")
      end
    end

    scenario "Clicking outside pdf or next pdf removes annotation mode" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
      expect(page).to have_content("CaseflowQueue")
      expect(page).to have_content(Document.find(2).type)

      add_comment_without_clicking_save("text")
      page.find("body").click
      expect(page).to_not have_css(".cf-pdf-placing-comment")
      add_comment_without_clicking_save("text")
      find("#button-next").click
      expect(page).to_not have_css(".cf-pdf-placing-comment")
    end

    scenario "Next and Previous buttons move between docs" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
      find("h3", text: "Document information").click
      expect(find(".cf-document-type")).to have_text("Form 9")
      find("#button-next").click

      expect(find(".cf-document-type")).to have_text("BVA Decision")
      find("#button-previous").click
      find("#button-previous").click
      expect(find(".cf-document-type")).to have_text("NOD")
    end

    scenario "Rotating documents" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"

      expect(get_computed_styles("#rotationDiv1", "transform"))
        .to eq "matrix(1, 0, 0, 1, 0, 0)"

      safe_click "#button-rotation"

      # The actual style is "matrix(0, 1, -1, 0, 0, -90)" but capybara has floating-point math
      # errors on the zero values. Instead, we check to ensure that the div was rotated by -90 degrees
      expect(get_computed_styles("#rotationDiv1", "transform").include?("-90"))
        .to be true
    end

    scenario "Arrow keys to navigate through documents" do
      def expect_doc_type_to_be(doc_type)
        expect(find(".cf-document-type")).to have_text(doc_type)
      end

      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"
      expect(page).to have_content("CaseflowQueue")

      add_comment(text: "comment text")

      expect(page.find("#comments-header")).to have_content("Page 1")
      click_on "Edit"
      find("h3", text: "Document information").click
      find("#editCommentBox-1").send_keys(:arrow_left)
      expect_doc_type_to_be "Form 9"
      find("#editCommentBox-1").send_keys(:arrow_right)
      expect_doc_type_to_be "Form 9"

      click_on "Cancel"
      find("body").send_keys(:arrow_right)
      expect_doc_type_to_be "BVA Decision"

      find("body").send_keys(:arrow_left)
      expect_doc_type_to_be "Form 9"

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

    scenario "Add, edit, share, and delete comments" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("CaseflowQueue")

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

      # Share the comment
      click_on "Share"

      # Expect there to be a link to this comment in the modal
      expect(page).to have_content("#{current_url}?annotation=1")

      # Close the share modal
      click_on "Close"

      # Delete the comment
      click_on "Delete"

      # Confirm the delete
      expect(page).to have_content "Delete Comment"
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

      # Delete modal should appear when removing all text from a comment
      expect(page).to have_content "Delete Comment"
      click_on "Confirm delete"

      # Comment should be removed
      expect(page).to_not have_css(".comment-container")
    end

    context "when comment box contains only whitespace characters" do
      scenario "save button is disabled and alt+enter doesn't trigger save" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
        add_comment_without_clicking_save(random_whitespace_no_tab)
        expect(find("#button-save")["disabled"]).to eq("true")

        # alt+enter doesn't save
        find("body").send_keys [:alt, :enter]
        expect(find("#button-save")["disabled"]).to eq("true")
        expect(Document.find(documents[0].id).annotations.empty?).to eq(true)
      end
    end

    context "existing comment edited to contain only whitespace characters" do
      let!(:annotations) do
        [Generators::Annotation.create(
          comment: Generators::Random.word_characters,
          document_id: documents[0].id
        )]
      end
      let(:comment_id) { annotations.length }

      scenario "prompts delete modal to appear" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

        find("#button-edit-comment-#{comment_id}").click
        fill_in "editCommentBox-#{comment_id}", with: random_whitespace_no_tab
        click_on "Save"

        # Delete modal should appear.
        expect(page).to have_css("#Delete-Comment-button-id-1")
      end
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
          ),
          Generators::Annotation.create(
            comment: "comment with a * char in it",
            document_id: documents[0].id,
            y: 350
          )
        ]
      end

      scenario "Documents and Comments toggle button" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on "Comments"
        expect(page).to have_content("another comment")
        expect(page).to have_content("how's it going")

        # A doc without a comment should not show up
        expect(page.has_no_content?(documents[2].type)).to eq(true)

        # Filter properly escapes characters
        fill_in "searchBar", with: "*"
        expect(page).to have_content(annotations[6].comment)

        # Filtering the document list should work in "Comments" mode.
        fill_in "searchBar", with: "form"
        expect(page.has_no_content?(documents[0].type)).to eq(true)
        expect(page).to have_content(documents[1].type)

        click_on "Documents"
        expect(page.has_no_content?("another comment")).to eq(true)
        expect(page.has_no_content?("how's it going")).to eq(true)
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
      scenario "Leave annotation with keyboard" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
        assert_selector(".commentIcon-container", count: 6)
        find("body").send_keys [:alt, "c"]
        expect(page).to have_css(".cf-pdf-placing-comment")
        assert_selector(".commentIcon-container", count: 7)

        def placing_annotation_icon_position
          element_position "#canvas-cursor-0"
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
      # :nocov:

      scenario "Jump to section for a comment" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        annotation = documents[1].annotations[0]

        click_button("expand-#{documents[1].id}-comments-button")

        click_link("Jump to section")

        # Wait for PDFJS to render the pages
        expect(page).to have_css(".page")

        # Somewhere in the spaghetti of the 2.0 reader, the page provided to the jump to methods is being
        # set to page - 1, so it is jumping to the previous page. This will manually set the page number to
        # what it should be without directly using the annotation object, since that would defeat the point
        page_number = page.find("input.page-progress-indicator-input").value.to_i
        page.find("input.page-progress-indicator-input").click.set((page_number + 1).to_s)

        # Check for comment icon on page
        expect(page).to have_css("#commentIcon-container-#{annotation.id}")
      end

      scenario "Scroll to comment" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[0].type

        element_id = "cf-sidebar-accordion"
        scroll_to(id: element_id, value: 0)

        # Wait for PDFJS to render the pages
        expect(page).to have_css(".page")

        # Click on the second to last comment icon (last comment icon is off screen)
        all(
          ".commentIcon-container",
          wait: 3,
          count: documents[0].annotations.reload.size
        )[annotations.size - 4].click

        # Make sure the comment icon and comment are shown as selected
        expect(find(".comment-container-selected").text).to eq "baby metal 4 lyfe"

        id = "#{annotations[annotations.size - 4].id}-filter-1"

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
        element_class = "ReactVirtualized__Grid__innerScrollContainer"
        original_scroll = scrolled_amount(element_class)

        # Click on the off screen comment (0 through 4 are on screen)
        find("#comment-5").click
        after_click_scroll = scrolled_amount(element_class)

        expect(after_click_scroll - original_scroll).to be > 0

        # Make sure the comment icon and comment are shown as selected
        expect(page).to have_css(".comment-container-selected")
        id = "#{annotations[4].id}-filter-1"

        # This filter is the blue highlight around the comment icon
        find("g[filter=\"url(##{id})\"]")
      end

      scenario "Follow comment deep link" do
        annotation = documents[1].annotations[0]
        # Open the document list before trying to go to deep link to pre-load the data
        visit "/reader/appeal/#{appeal.vacols_id}/documents/"
        visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[1].id}?annotation=#{annotation.id}"

        expect(page).to have_content(annotation.comment)
        expect(page).to have_css(".page")
        expect(page).to have_css("#commentIcon-container-#{annotation.id}")
      end

      scenario "Scrolling pages changes page numbers" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents/2"

        expect(page).to have_content("IN THE APPEAL")
        expect(page).to have_css(".page")
        expect(page).to have_field("page-progress-indicator-input", with: "1")

        all(".ReactVirtualized__Grid").last.scroll_to(0, 2000)

        expect(page).to_not have_field("page-progress-indicator-input", with: "1")
      end

      context "When document 3 is a 147 page document" do
        before do
          documents.push(
            Generators::Document.create(
              filename: "My SOC",
              type: "SOC",
              received_at: 5.days.ago,
              vbms_document_id: 5,
              category_medical: true,
              category_other: true
            )
          )
        end

        scenario "Switch between pages to ensure rendering" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[3].id}"
          page.find("input.page-progress-indicator-input").click.set("23")

          expect(find("#pageContainer23")).to have_content("Rating Decision")
          expect(page).to have_field("page-progress-indicator-input", with: "23")

          # Entering invalid values leaves the viewer on the same page.
          page.find("input.page-progress-indicator-input").click.set("abcd")

          expect(page).to have_css("#pageContainer23")
          expect(page).to have_field("page-progress-indicator-input", with: "23")
        end
      end
    end

    # The zoom level is adjusted by changing the height of the container row in react-virtualized
    # Checking for text on the pages is flaky because of inconsistencies with react-virtualized rendering
    scenario "Zooming changes the size of pages" do
      # This is set in client/app/2.0/store/constants/reader.js as ZOOM_RATE
      zoom_rate = 0.3

      # Get document #2 which is from lib/pdfs/FakeDecisionDocument.pdf
      visit "/reader/appeal/#{appeal.vacols_id}/documents/2"

      # Wait for the page to load
      expect(page).to have_content("IN THE APPEAL")
      original_height = page.find("#pageContainer1").style("height")["height"].to_f

      # Zoom in and verify zoom rate
      find("#button-zoomIn").click
      ratio = (page.find("#pageContainer1").style("height")["height"].to_f / original_height).round(1)
      expect(ratio).to eq(1 + zoom_rate)

      # Reset zoom amount
      find("#button-fit").click
      expect(page.find("#pageContainer1").style("height")["height"].to_f).to eq(original_height)

      # Zoom out and verify zoom rate
      find("#button-zoomOut").click
      ratio = (page.find("#pageContainer1").style("height")["height"].to_f / original_height).round(1)
      expect(ratio).to eq(1 - zoom_rate)
    end

    scenario "Open single document view and open/close sidebar" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type
      find("h3", text: "Document information").click

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

      find("h3", text: "Document information").click
      click_accordion_header(0)
      expect(page).to_not have_content("Document Type")
      click_accordion_header(0)
      expect(page).to have_content("Document Type")

      click_accordion_header(1)
      expect(page).to_not have_content("Procedural")
      click_accordion_header(1)
      expect(page).to have_content("Procedural")

      click_accordion_header(2)
      expect(page).to_not have_content("Select or tag issues")
      click_accordion_header(2)
      expect(page).to have_content("Select or tag issues")

      click_accordion_header(3)
      expect(page).to_not have_content("Add a comment")
      click_accordion_header(3)
      expect(page).to have_content("Add a comment")
    end

    scenario "Document information contains Claims information" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type
      find("h3", text: "Document information").click

      expect(page).to have_content("Document Type")
      expect(page).to have_content("Document Description")
      expect(find("#document_description").text).to eq(documents[0].description)
      expect(page).to have_content("BVA Decision")
      expect(page).to have_content("AOD")
      expect(page).to have_content("Veteran ID")
      expect(page).to have_content(appeal.vbms_id)
      expect(page).to have_content("Type")
      expect(page).to have_content(appeal.type)
      expect(page).to have_content("Docket Number")
      expect(page).to have_content(appeal.docket_number)
      expect(page).to have_content("Regional Office")
      expect(page).to have_content("#{appeal.regional_office.key} - #{appeal.regional_office.city}")
      expect(page).to have_content("Issues")
      expect(page.all("td", text: appeal.issues[0].type).count).to eq(appeal.undecided_issues.length)
      appeal.issues do |issue|
        expect(page).to have_content(issue.type)
        issue.levels do |level|
          expect(page).to have_content(level)
        end
      end
    end

    scenario "Update Document Description" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type
      find("h3", text: "Document information").click
      find("#document_description-edit").click
      find("#document_description-save")
      fill_in "document_description", with: "New Description"
      find("#document_description-save").click

      expect(find("#document_description").text).to eq("New Description")
    end

    scenario "Update Document Description with Enter" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/"
      click_on documents[0].type
      find("h3", text: "Document information").click
      find("#document_description-edit").click
      find("#document_description-save")
      fill_in "document_description", with: "Another New Description"

      find("#document_description").send_keys [:enter]

      expect(find("#document_description").text).to eq("Another New Description")
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

    scenario "Sort order" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      # this will wait for the document count to display before expecting anything
      find("div.num-of-documents", text: "#{documents.length} Documents")

      # confirm that the documents are sorted by receipt date ascending (oldest first)
      sorted_documents = documents.sort_by(&:received_at).reverse!

      sorted_documents.each_with_index do |doc, index|
        selector = "#documents-table-body tr:nth-child(#{index + 1}) td.receipt-date-column"
        expect(find(selector).text).to eq doc.received_at.strftime("%m/%d/%Y")
      end
    end

    scenario "Categories" do
      cats = {
        procedural: "Procedural",
        medical: "Medical",
        other: "Other Evidence",
        case_summary: "Case Summary"
      }

      def cats_in_row(row)
        selector = "#documents-table-body tr:nth-child(#{row}) .categories-column .cf-no-styling-list"
        all(selector).map { |elem| elem["aria-label"] }
      end

      def cats_in_header
        all(".cf-pdf-header .cf-pdf-doc-category-icons .cf-no-styling-list").map { |elem| elem["aria-label"] }
      end

      step "visit the documents index" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        # this will wait for the document count to display before expecting anything
        find("div.num-of-documents", text: "#{documents.length} Documents")

        # these are the categories we expect the documents to have in the expected sort order
        expect(cats_in_row(1)).to match_array [cats[:case_summary]]
        expect(cats_in_row(2)).to match_array [cats[:medical], cats[:other], cats[:case_summary]]
        expect(cats_in_row(3)).to match_array [cats[:procedural], cats[:case_summary]]
      end

      step "edit the BVA Decision document categories" do
        click_on documents[0].type

        # this will wait for the document title to display before expecting anything
        find(".cf-pdf-header .cf-pdf-doc-type-button-container", text: "BVA Decision")
        expect(cats_in_header).to match_array [cats[:procedural], cats[:case_summary]]

        find(".checkbox-wrapper-procedural").click
        find(".checkbox-wrapper-medical").click

        # this will wait for the categories to update in the header before expecting anything
        find(".cf-pdf-header li[aria-label='Medical']")
        expect(cats_in_header).to match_array [cats[:medical], cats[:case_summary]]
      end

      step "return to the index and view the Form 9 document" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        # this will wait for the document count to display before expecting anything
        find("div.num-of-documents", text: "#{documents.length} Documents")

        click_on documents[1].type

        # this will wait for the document title to display before expecting anything
        find(".cf-pdf-header .cf-pdf-doc-type-button-container", text: "Form 9")
        expect(cats_in_header).to match_array [cats[:medical], cats[:other], cats[:case_summary]]
        expect(find("#case_summary", visible: false).disabled?).to be true
      end

      step "view the previous document, NOD" do
        find("#button-previous").click

        # this will wait for the document title to display before expecting anything
        find(".cf-pdf-header .cf-pdf-doc-type-button-container", text: "NOD")
        expect(find("#procedural", visible: false).checked?).to be false
        expect(find("#medical", visible: false).checked?).to be false
        expect(find("#other", visible: false).checked?).to be false
        expect(find("#case_summary", visible: false).checked?).to be true
      end
    end

    scenario "Claim Folder Details" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      appeal_info = appeal.to_hash(issues: appeal.issues)
      issues_info = appeal.undecided_issues

      expect(page).to have_content("#{appeal.veteran_full_name}'s Claims Folder")
      expect(page).to have_content("Claims folder details")

      # Test the document count updates after viewing a document
      expect(page).to have_content("You've viewed 0 out of #{documents.length} documents")
      click_on documents[0].type
      click_on "Back"
      expect(page).to have_content("You've viewed 1 out of #{documents.length} documents")

      find(".rc-collapse-header", text: "Claims folder details").click
      regional_office = "#{appeal_info['regional_office'][:key]} - #{appeal_info['regional_office'][:city]}"
      expect(page).to have_content(appeal_info["vbms_id"])
      expect(page).to have_content(appeal_info["type"])
      expect(page).to have_content(appeal_info["docket_number"])
      expect(page).to have_content(regional_office)

      # all the current issues listed in the UI
      issue_list = all("#claims-folder-issues tr")
      expect(issue_list.count).to eq(issues_info.length)
      issue_list.each_with_index do |issue, index|
        expect(issue.text).to include issues_info[index].type

        # verifying the level information is being shown as part of the issue information
        issues_info[index].levels.each_with_index do |level, level_index|
          expect(level).to include issues_info[index].levels[level_index]
        end
      end
    end

    context "Tags" do
      let(:new_tag_text) { "Foo" }

      scenario "adding and deleting tags" do
        TAG1 = "Medical"
        TAG2 = "Law document"

        DOC2_TAG1 = "Appeal Document"

        SELECT_VALUE_LABEL_CLASS = ".cf-select__multi-value__label"

        visit "/reader/appeal/#{appeal.vacols_id}/documents"
        click_on documents[0].type

        fill_in "tags", with: TAG1

        # making sure there is a dropdown showing up when text is entered
        expect(page).to have_css(".cf-select__menu", wait: 5)

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
        cancel_icons = page.all(".cf-select__multi-value__remove", count: 1)

        # delete all tags
        cancel_icons[0].click

        # expecting the page not to have any tags
        expect(page).not_to have_css(SELECT_VALUE_LABEL_CLASS, text: DOC2_TAG1)
        expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 0)

        visit "/reader/appeal/#{appeal.vacols_id}/documents"

        click_on documents[0].type

        # verify that the tags on the previous document still exist
        expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 4)
      end

      scenario "create new tag" do
        visit "/reader/appeal/#{appeal.vacols_id}/documents"
        click_on documents[1].type
        find(".cf-select__control").click

        expect_any_instance_of(TagController).to receive(:create).and_call_original
        fill_in "tags", with: (new_tag_text + "\n")
        expect(Tag.last.text).to eq("Foo")
      end

      context "Share tags among all documents in a case" do
        scenario "Shouldn't show auto suggestions" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents"
          click_on documents[0].type
          find("#tags").click
          expect(page).not_to have_css(".cf-select__menu")
        end

        # :nocov:
        scenario "Should show correct auto suggestions" do
          visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[1].id}"
          find(".cf-select__control").click
          expect(page).to have_css(".cf-select__menu")

          tag_options = find_all(".cf-select__option")
          expect(tag_options.count).to eq(2)

          documents[0].tags.each_with_index do |tag, index|
            expect(tag_options[index]).to have_content(tag.text)
          end

          NEW_TAG_TEXT = "New Tag3"
          fill_in "tags", with: (NEW_TAG_TEXT + "\n")

          # going to the document[0] page
          visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
          find(".cf-select__control").click
          expect(page).to have_css(".cf-select__menu")

          # making sure correct tag options exist
          tag_options = find_all(".cf-select__option")
          expect(tag_options.count).to eq(1)
          expect(tag_options[0]).to have_content(NEW_TAG_TEXT)

          # removing an existing tag
          select_control = find(".cf-issue-tag-sidebar").find(".cf-select__control")
          removed_value_text = select_control.find_all(".cf-select__multi-value")[0].text
          select_control.find_all(".cf-select__multi-value__remove")[0].click
          expect(page).not_to have_css(".cf-select__multi-value__label", text: removed_value_text)

          find(".cf-select__control").click

          # again making sure the correct tag options exist
          expect(page).to have_css(".cf-select__menu")
          tag_options = find_all(".cf-select__option")
          expect(tag_options.count).to eq(1)
          expect(tag_options[0]).to have_content(NEW_TAG_TEXT)
        end
        # :nocov:
      end
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

    scenario "Document viewer when doc list is filtered" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      fill_in "searchBar", with: documents[0].type
      click_on documents[0].type

      expect(page).to have_no_selector("#button-next")
      expect(page).to have_no_selector("#button-previous")
      expect(page).to have_selector("#backToClaimsFolder")
    end

    scenario "When user search term is not found" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      search_query = "does not exist in annotations"
      fill_in "searchBar", with: search_query

      expect(page).to have_content("Search results not found")
      expect(page).to have_content(search_query)
    end

    def open_search_bar
      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

      search_bar = find(".cf-pdf-search")
      search_bar.click

      expect(search_bar).not_to match_css(".hidden")
    end

    scenario "Search Document Text" do
      open_search_bar

      search_input = find("#search-ahead")
      internal_text = find("#search-internal-text")

      expect(search_input).to match_xpath("//input[@placeholder='Type to search...']")

      search_input.click
      fill_in "search-ahead", with: "decision"

      expect(search_input.value).to eq("decision")
      expect(internal_text).to have_xpath("//input[@value='1 of 2']")
    end

    scenario "Search Text Resets on Change Document" do
      open_search_bar

      search_input = find("#search-ahead")
      next_doc = find("#button-previous")

      fill_in "search-ahead", with: "decision"
      expect(search_input.value).to eq("decision")
      next_doc.click
      expect(search_input.value).to eq("")
    end

    scenario "Navigate Search Results with Keyboard" do
      open_search_bar

      internal_text = find("#search-internal-text")

      fill_in "search-ahead", with: "decision"

      expect(internal_text.value).to eq "1 of 2"

      find("body").send_keys [:meta, "g"]

      expect(internal_text.value).to eq "2 of 2"
    end

    scenario "Show and Hide Document Searchbar with Keyboard" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

      expect(page).to have_content(Document.find(documents[0].id).type)
      find("body").send_keys [:meta, "f"]
      search_bar = find(".cf-search-bar")
      expect(search_bar).not_to match_css(".hidden")

      find("body").send_keys [:escape]

      expect(page).not_to have_selector(".cf-search-bar")
    end

    scenario "Navigating Search Results scrolls page" do
      open_search_bar
      elem_name = "ReactVirtualized__Grid__innerScrollContainer"
      expect(scrolled_amount(elem_name)).to be(0)

      fill_in "search-ahead", with: "just"

      expect(find("#search-internal-text")).to have_xpath("//input[@value='1 of 3']")

      first_match_scroll_top = scrolled_amount(elem_name)

      expect(first_match_scroll_top).to be > 0

      find(".cf-next-match").click
      expect(scrolled_amount(elem_name)).to be > first_match_scroll_top

      # this doc has 3 matches for "decision", search index wraps around
      find(".cf-next-match").click
      find(".cf-next-match").click
      expect(scrolled_amount(elem_name)).to be <= first_match_scroll_top
      expect(scrolled_amount(elem_name)).to be >= first_match_scroll_top - 5
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

    scenario "can open a doc, go to previous doc in file, return to list, and verify read status" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      expect(page).to_not have_css("#read-indicator")

      page.find("#documents-table-body").scroll_to(:bottom)
      original_scroll_position = page.find("#documents-table-body").evaluate_script("this.scrollTop")
      click_on documents.last.type
      safe_click "#button-previous"
      click_on "Back"

      expect(page).to have_content("#{num_documents} Documents")
      expect(find("#table-row-#{documents.count - 1}")).to have_css("#read-indicator")
      expect(page.find("#documents-table-body").evaluate_script("this.scrollTop")).to eq(original_scroll_position)
    end
  end

  context "with a single document that errors when we fetch it" do
    # TODO(lowell): The webdriver we use caches HTTP requests in the browser, and that cache
    # persists between subtests. Capybara does not easily allow us to clear the browser
    # cache, so we use a document ID that will probably not have been used by a previous
    # test to avoid the issue of a request to /document/1/pdf returning a cached response
    # instead of an error that would trigger the state we desire.
    # Created issue #3883 to address this browser cache retention issue.
    let(:documents) { [Generators::Document.create(id: rand(999_999..1_000_997))] }

    scenario "causes individual file view will display error message" do
      allow_any_instance_of(DocumentController).to receive(:pdf).and_raise(StandardError)
      visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"
      expect(page).to have_content("Unable to load document")
    end
  end

  # This test appears to mess with mocked data, so we run it last...
  context "Document is updated" do
    let(:series_id) { SecureRandom.uuid }
    let(:document_ids_in_series) { [SecureRandom.uuid, SecureRandom.uuid] }
    let!(:fetch_documents_responses) do
      document_ids_in_series.map do |document_id|
        {
          documents: [Generators::Document.build(vbms_document_id: document_id, series_id: series_id)],
          manifest_vbms_fetched_at: Time.now.utc,
          manifest_vva_fetched_at: Time.now.utc
        }
      end
    end
    let!(:appeal) do
      Generators::LegacyAppealV2.create
    end

    before do
      allow(VBMSService).to receive(:fetch_documents_for).with(appeal, anything).and_return(
        fetch_documents_responses[0],
        fetch_documents_responses[1]
      )
    end

    it "should alert user" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Reader")
      click_on Document.last.type
      expect(page).to have_content("Document Viewer")

      add_comment("test comment")

      visit "/reader/appeal/#{appeal.vacols_id}/documents"
      expect(page).to have_content("Reader")
      click_on Document.last.type

      expect(page).to have_content("test comment")
      expect(page).to_not have_content("This document has been updated")
    end
  end
end

# Generate some combination of whitespace characters between 1 and len characters long.
# Do not include tab character becuase inserting tab will cause Capybara to change the focused DOM element.
def random_whitespace_no_tab(len = 16)
  Generators::Random.from_set([" ", "\n", "\r"], len) + " "
end
