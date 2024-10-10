# frozen_string_literal: true

RSpec.feature "Hearing worksheet for Hearing Prep", :all_dbs do
  let!(:current_user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let!(:legacy_hearing) do
    create(
      :legacy_hearing,
      user: current_user,
      hearing_day: create(:hearing_day, regional_office: "RO42", request_type: HearingDay::REQUEST_TYPES[:video])
    )
  end

  scenario "Hearing worksheet page displays worksheet information" do
    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"

    expect(page).to have_content("HEARING TYPE\nVideo")
    expect(page).to have_content("Docket #" + legacy_hearing.docket_number)
    expect(page.title).to eq legacy_hearing.veteran_fi_last_formatted + "'s Hearing Worksheet"
  end

  context "worksheet header" do
    let!(:legacy_hearing_two) do
      create(:legacy_hearing,
             user: current_user,
             hearing_day: legacy_hearing.hearing_day)
    end

    scenario "Hearing worksheet switch veterans" do
      visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"
      find(".cf-select__control").click
      find("#react-select-2-option-0").click
      expect(page).to have_current_path("/hearings/" + legacy_hearing.external_id.to_s + "/worksheet")
      expect(page).to have_content(legacy_hearing.veteran_first_name)

      find(".cf-select__control").click
      find("#react-select-2-option-1").click
      expect(page).to have_current_path("/hearings/" + legacy_hearing_two.external_id.to_s + "/worksheet")
      expect(page).to have_content(legacy_hearing_two.veteran_first_name)
    end
  end

  scenario "Hearing worksheet default summary shows up" do
    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"
    expect(page).to have_content("Contentions")
    expect(page).to have_content("Evidence")
    expect(page).to have_content("Comments and special instructions to attorneys")
  end

  scenario "Worksheet saves on refresh" do
    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"
    page.find(".public-DraftEditor-content").set("These are the notes being taken here")
    fill_in "appellant-vet-rep-name", with: "This is a rep name"
    fill_in "appellant-vet-witness", with: "This is a witness"
    fill_in "worksheet-military-service", with: "This is military service"

    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"
    expect(page).to have_content("This is a rep name")
    expect(page).to have_content("This is a witness")
    expect(page).to have_content("These are the notes being taken here")
    expect(page).to have_content("This is military service")

    visit "/hearings/worksheet/print?keep_open=true&hearing_ids=" + legacy_hearing.external_id.to_s
    expect(page).to have_content("This is a rep name")
    expect(page).to have_content("This is a witness")
    expect(page).to have_content("These are the notes being taken here")
    expect(page).to have_content("This is military service")
  end

  scenario "Worksheet adds, deletes, edits, and saves user created issues" do
    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"

    click_on "button-addIssue-1"
    fill_in "3-issue-description", with: "This is the description"
    fill_in "3-issue-notes", with: "This is a note"
    fill_in "3-issue-disposition", with: "This is a disposition"

    expect(page).to have_content("Vba_burial:")
    find("#cf-issue-delete-11").click
    click_on "Confirm delete"
    find("#cf-issue-delete-12").click
    click_on "Confirm delete"
    expect(page).to_not have_content("Vba_burial:")

    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"
    expect(page).to have_content("This is the description")
    expect(page).to have_content("This is a note")
    expect(page).to have_content("This is a disposition")
    expect(page).to_not have_content("Service Connection")
    expect(HearingView.where(hearing: legacy_hearing).count).to eq(1)
  end

  context "Multiple appeal streams" do
    before do
      vbms_id = legacy_hearing.appeal.vbms_id
      create(:case_with_form_9, bfcorlid: vbms_id, case_issues:
          [create(:case_issue), create(:case_issue)])
    end

    scenario "Numbering is consistent" do
      visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"

      click_on "button-addIssue-2"
      expect(page).to have_content("5.")
      find("#cf-issue-delete-11").click
      click_on "Confirm delete"
      expect(page).to_not have_content("5.")
    end
  end

  scenario "Can click from hearing worksheet to reader" do
    visit "/hearings/" + legacy_hearing.external_id.to_s + "/worksheet"
    link = find("#review-claims-folder")
    link_href = link[:href]
    expect(page).to have_content("Review claims folder")
    click_on "Review claims folder"
    new_window = windows.last
    page.within_window new_window do
      visit link_href
      expect(page).to have_content("You've viewed 0 out of 3 documents")
    end
  end

  context "Worksheet for AMA hearings" do
    let(:ama_hearing) { create(:hearing, :with_tasks, judge: current_user) }
    let!(:request_issue) { create(:request_issue, decision_review: ama_hearing.appeal) }

    scenario "Can save information for ama hearings" do
      visit "/hearings/" + ama_hearing.external_id.to_s + "/worksheet"
      page.find(".public-DraftEditor-content").set("These are the notes being taken here")
      fill_in "appellant-vet-rep-name", with: "This is a rep name"
      fill_in "appellant-vet-witness", with: "This is a witness"
      fill_in "worksheet-military-service", with: "This is military service"
      find("label", text: "Hearing Prepped").click

      visit "/hearings/" + ama_hearing.external_id.to_s + "/worksheet"

      expect(page).to have_content("This is a rep name")
      expect(page).to have_content("This is a witness")
      expect(page).to have_content("These are the notes being taken here")
      expect(page).to have_content("This is military service")
      expect(page).to have_field("Hearing Prepped", checked: true, visible: false)
    end

    scenario "Can save preliminary impressions for ama hearings" do
      visit "/hearings/" + ama_hearing.external_id.to_s + "/worksheet"
      find("label", text: "Re-Open").click
      find("label", text: "Remand").click
      find("label", text: "Allow").click
      find("label", text: "Dismiss").click
      find("label", text: "Deny").click

      visit "/hearings/" + ama_hearing.external_id.to_s + "/worksheet"
      expect(find_field("Re-Open", visible: false)).to be_checked
      expect(find_field("Remand", visible: false)).to be_checked
      expect(find_field("Allow", visible: false)).to be_checked
      expect(find_field("Dismiss", visible: false)).to be_checked
      expect(find_field("Deny", visible: false)).to be_checked
    end
  end

  context "while accessing as a VSO user" do
    let!(:vso_user) { create(:user, :vso_role) }
    let(:ama_hearing) { create(:hearing, :with_tasks) }

    before { User.authenticate!(user: vso_user) }

    scenario "they are denied access" do
      visit "/hearings/" + ama_hearing.external_id.to_s + "/worksheet"
      expect(page).to have_content(COPY::UNAUTHORIZED_PAGE_ACCESS_MESSAGE)
    end
  end
end
