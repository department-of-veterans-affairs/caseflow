require "rails_helper"

def scroll_position
  page.evaluate_script("document.getElementById('scrollWindow').scrollTop")
end

def scroll_to(value)
  page.execute_script("document.getElementById('scrollWindow').scrollTop=#{value}")
end

RSpec.feature "Reader" do
  let(:vacols_record) { :remand_decided }

  # Currently the vbms_document_ids need to be set since they correspond to specific
  # files to load when we fetch content.
  let(:documents) do
    [
      Generators::Document.create(
        filename: "BVA Decision",
        type: "BVA Decision",
        received_at: 7.days.ago,
        vbms_document_id: 5,
        category_procedural: true
      ),
      Generators::Document.create(
        filename: "Form 9",
        type: "Form 9",
        received_at: 5.days.ago,
        vbms_document_id: 2,
        category_medical: true,
        category_other: true
      ),
      Generators::Document.create(
        filename: "NOD",
        type: "NOD",
        received_at: 1.day.ago,
        vbms_document_id: 3
      )
    ]
  end

  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["Reader"])
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

    find("#categories-header .table-icon").send_keys :enter
    expect_dropdown_filter_to_be_visible
  end

  scenario "Add comment" do
    visit "/reader/appeal/#{appeal.vacols_id}/documents"
    expect(page).to have_content("Caseflow Reader")

    # Click on the link to the first file
    click_on documents[0].filename

    # Ensure PDF content loads (using :all because the text is hidden)
    expect(page).to have_content(:all, "Important Decision Document!!!")

    # Add a comment
    click_on "button-AddComment"

    # pageContainer1 is the id pdfJS gives to the div holding the first page.
    find("#pageContainer1").click
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
    let!(:annotation) do
      Generators::Annotation.create(
        comment: "hello world",
        document_id: documents[0].id,
        y: 750
      )
    end

    scenario "Scroll to comment" do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"

      click_on documents[0].filename

      expect(page).to have_content(annotation.comment)

      # Wait for PDFJS to render the pages
      expect(page).to have_css(".page")

      # Click on the comment and ensure the scroll position changes
      # by the y value the comment.
      original_scroll = scroll_position
      find("#comment0").click
      after_click_scroll = scroll_position

      expect(after_click_scroll - original_scroll).to be > 0
    end
  end

  scenario "Scrolling renders pages" do
    visit "/reader/appeal/#{appeal.vacols_id}/documents"

    click_on documents[0].filename
    expect(page).to have_css(".page")

    # Expect only the first page to be reneder on first load
    # But if we scroll second page should be rendered and
    # we should be able to find text from the second page.
    expect(page).to_not have_content("Banana. Banana who")
    scroll_to(500)
    expect(page).to have_content("Banana. Banana who")
  end

  scenario "Open single document view" do
    visit "/reader/appeal/#{appeal.vacols_id}/documents/#{documents[0].id}"

    # Expect only the first page of the pdf to be rendered
    expect(page).to_not have_content("Important Decision Document!!!")
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

    click_on documents[0].filename

    expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Procedural"])

    find(".checkbox-wrapper-procedural").click
    find(".checkbox-wrapper-medical").click

    expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Medical"])

    visit "/reader/appeal/#{appeal.vacols_id}/documents"

    doc_0_categories =
      get_aria_labels all(".section--document-list table tr:first-child .cf-document-category-icons li")
    expect(doc_0_categories).to eq(["Medical"])

    click_on documents[1].filename
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
    click_on documents[0].filename

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
    click_on documents[1].filename
    find(".Select-control").click
    input_element = find(".Select-input > input")
    input_element.click.native.send_keys(DOC2_TAG1, :enter)

    expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, text: DOC2_TAG1)
    expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 3)

    # getting remove buttons of all tags
    cancel_icons = page.all(".Select-value-icon")

    # rubocop:disable all
    # delete all tags
    for i in (cancel_icons.length - 1).downto(0)
      cancel_icons[i].click
    end
    # rubocop:enable all

    # expecting the page not to have any tags
    expect(page).not_to have_css(SELECT_VALUE_LABEL_CLASS, text: DOC2_TAG1)
    expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 0)

    # go back to the first document
    find("#button-previous").click

    # verify that the tags on the previous document still exist
    expect(page).to have_css(SELECT_VALUE_LABEL_CLASS, count: 4)
  end

  scenario "Expand All and See More..Less tags" do
    visit "/reader/appeal/#{appeal.vacols_id}/documents"
    click_on documents[0].filename

    # Add a comment
    click_on "button-AddComment"

    # pageContainer1 is the id pdfJS gives to the div holding the first page.
    find("#pageContainer1").click
    fill_in "addComment", with: "Foo"
    click_on "Save"

    click_on "button-AddComment"

    # pageContainer1 is the id pdfJS gives to the div holding the first page.
    find("#pageContainer1").click
    fill_in "addComment", with: "Bar"
    click_on "Save"

    find(".Select-control").click
    input_element = find(".Select-input > input")
    input_element.click.native.send_keys("doc tag", :enter)
    input_element.click.native.send_keys("This is a Law Document", :enter)
    input_element.click.native.send_keys("Crazy Document", :enter)
    input_element.click.native.send_keys("Serviced Comment", :enter)
    input_element.click.native.send_keys("Tag tag tag 2", :enter)
    input_element.click.native.send_keys("Tag tag tag 3", :enter)
    input_element.click.native.send_keys("Piece of Pie", :enter)
        
    find("#button-backToDocuments").click

    expect(page).to have_content("See More...")
    first('.see-more-link-toggle').click
    expect(first('.document-list-issue-tags')).to have_css('.document-list-issue-tag', count: 9)
    expect(page).to have_content("See Less...")
    first('.see-more-link-toggle').click

    visit "/reader/appeal/#{appeal.vacols_id}/documents"
    click_on "Expand all"
    expect(page).to have_content("Foo")
    expect(page).to have_content("Bar")
    expect(first('.document-list-issue-tags')).
      to have_css('.document-list-issue-tag', count: 9)
    click_on "Collapse all"
    expect(first('.document-list-issue-tags')).
      to have_css('.document-list-issue-tag', maximum: 5)
    expect(page).not_to have_content("Foo")
    expect(page).not_to have_content("Bar")
  end
end
