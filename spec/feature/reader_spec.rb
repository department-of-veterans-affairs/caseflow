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
      )
    ]
  end

  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
  end

  let!(:current_user) do
    User.authenticate!(roles: ["System Admin"])
  end

  scenario "Add comment" do
    visit "/reader/appeal/#{appeal.vacols_id}/documents"
    expect(page).to have_content("Caseflow Reader")

    # Click on the link to the first file
    click_on documents[0].filename

    # Ensure PDF content loads (using :all because the text is hidden)
    expect(page).to have_content(:all, "Important Decision Document!!!")

    # Add a comment
    click_on "+ Add a Comment"

    # pageContainer1 is the id pdfJS gives to the div holding the first page.
    find("#pageContainer1").click
    fill_in "addComment", with: "Foo"
    click_on "Save"

    # Expect comment to be visible on page
    expect(page).to have_content("Foo")

    # Expect comment to be in database
    expect(documents[0].reload.annotations.first.comment).to eq("Foo")

    # Edit the comment
    click_on "Edit"
    fill_in "editComment", with: "FooBar"
    click_on "Save"

    # Expect edited comment to be visible on opage
    expect(page).to have_content("FooBar")

    # Expect comment to be in database
    expect(documents[0].reload.annotations.first.comment).to eq("FooBar")

    # Delete the comment
    click_on "Delete"

    # Confirm the delete
    click_on "Confirm Delete"

    # Expect the comment to be removed from the page
    expect(page).to_not have_content("FooBar")

    # Expect the comment to be removed from teh database
    expect(documents[0].reload.annotations.count).to eq(0)
  end

  context "When there is an existing annotation" do
    let!(:annotation) do
      Generators::Annotation.create(
        comment: "hello world",
        document_id: documents[0].id
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

      expect(after_click_scroll - original_scroll).to eq(annotation.y)
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

    doc_1_categories =
      get_aria_labels all(".section--document-list table tr:first-child .cf-document-category-icons li")
    expect(doc_1_categories).to eq(["Procedural"])

    doc_2_categories = get_aria_labels all(".section--document-list table tr:last-child .cf-document-category-icons li")
    expect(doc_2_categories).to eq(["Medical", "Other Evidence"])

    click_on documents[0].filename

    expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Procedural"])

    find(".checkbox-wrapper-procedural").click
    find(".checkbox-wrapper-medical").click

    expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Medical"])

    visit "/reader/appeal/#{appeal.vacols_id}/documents"

    doc_1_categories =
      get_aria_labels all(".section--document-list table tr:first-child .cf-document-category-icons li")
    expect(doc_1_categories).to eq(["Medical"])

    click_on documents[1].filename

    expect((get_aria_labels all(".cf-document-category-icons li"))).to eq(["Medical", "Other Evidence"])
  end

  scenario "Tags" do

    TAG_TEXT1 = "Medical"
    TAG_TEXT2 = "Law document"

    TAG_DOC2_TEXT1 = "Appeal Document"

    visit "/reader/appeal/#{appeal.vacols_id}/documents"
    click_on documents[0].filename
    find('.Select-control').click
    input_element = find('.Select-input > input')
    input_element.click.native.send_keys(TAG_TEXT1)

    # making sure there is a dropdown showing up when text is entered
    expect(page).to have_css('.Select-menu-outer')

    # enter the text
    input_element.send_keys(:enter)

    find('.Select-input > input').click.native.send_keys(TAG_TEXT2, :enter)

    # expecting the multi-selct to have the two new fields
    expect(page).to have_css('.Select-value-label', text: TAG_TEXT1)
    expect(page).to have_css('.Select-value-label', text: TAG_TEXT2)

    # adding new tags to another document
    visit "/reader/appeal/#{appeal.vacols_id}/documents"
    click_on documents[1].filename
    find('.Select-control').click
    input_element = find('.Select-input > input')
    input_element.click.native.send_keys(TAG_DOC2_TEXT1)

    expect(page).to have_css('.Select-value-label', text: TAG_DOC2_TEXT1)
  end
end
