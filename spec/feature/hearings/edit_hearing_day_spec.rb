# frozen_string_literal: true

RSpec.feature "Edit a Hearing Day", :all_dbs do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let!(:judge) do
    create(:user, css_id: "BVAAABSHIRE", full_name: "Judge Abshire")
    create(:staff, :judge_role, sdomainid: "BVAAABSHIRE", snamel: "Abshire", snamef: "Judge")
  end

  let!(:hearing_day) do
    create(:hearing_day, request_type: "C", room: "2", judge_id: judge.id)
  end

  let!(:coordinator) do
    create(:staff, :hearing_coordinator)
  end
  let!(:caseflow_coordinator) do
    User.find_by_css_id_or_create_with_default_station_id(coordinator.sdomainid)
  end

  before do
    HearingsManagement.singleton.add_user(caseflow_coordinator)
  end

  context "When editing a Hearing Day" do
    scenario "Verify initial fields present when modal opened" do
      visit "hearings/schedule"
      find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click
      expect(page).to have_content("Edit Hearing Day")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
      find("button", text: "Edit Hearing Day").click
      expect(page).to have_content("Edit Hearing Day")
      expect(page).to have_content("Change Room")
      expect(page).to have_content("Change VLJ")
      expect(page).to have_content("Change Coordinator")
      expect(page).to have_content("Select Room")
      expect(page).to have_content("Select VLJ")
      expect(page).to have_content("Select Hearing Coordinator")
      expect(page).to have_content("Notes")
    end
  end

  scenario "Verify room dropdown enabled when checkbox clicked" do
    visit "hearings/schedule"
    find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click
    expect(page).to have_content("Edit Hearing Day")
    expect(page).to have_content("No Veterans are scheduled for this hearing day.")
    find("button", text: "Edit Hearing Day").click
    expect(page).to have_content("Edit Hearing Day")
    dropdowns = page.all(".Select-control")
    dropdowns[0].click
    expect do
      dropdowns[0].sibling(".Select-menu-outer").find("div .Select-option", text: "1 (1W200A)").click
    end.to raise_error(Capybara::ElementNotFound)
    find("label[for=roomEdit]").click
    dropdowns[0].click
    dropdowns[0].sibling(".Select-menu-outer").find("div .Select-option", text: "1 (1W200A)").click
    find("button", text: "Confirm").click
    expect(page).to have_content("You have successfully completed this action")
  end

  scenario "Verify VLJ dropdown enabled when checkbox clicked" do
    visit "hearings/schedule"
    find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click
    expect(page).to have_content("Edit Hearing Day")
    expect(page).to have_content("No Veterans are scheduled for this hearing day.")
    find("button", text: "Edit Hearing Day").click
    expect(page).to have_content("Edit Hearing Day")
    dropdowns = page.all(".Select-control")
    dropdowns[1].click
    expect do
      dropdowns[1].sibling(".Select-menu-outer").find("div .Select-option", text: "Judge Abshire").click
    end.to raise_error(Capybara::ElementNotFound)
    find("label[for=vljEdit]").click
    dropdowns[1].click
    dropdowns[1].sibling(".Select-menu-outer").find("div .Select-option", text: "Judge Abshire").click
    find("button", text: "Confirm").click
    expect(page).to have_content("You have successfully completed this action")
  end

  scenario "Verify Coordinator dropdown enabled when checkbox clicked" do
    visit "hearings/schedule"
    find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click
    expect(page).to have_content("Edit Hearing Day")
    expect(page).to have_content("No Veterans are scheduled for this hearing day.")
    find("button", text: "Edit Hearing Day").click
    expect(page).to have_content("Edit Hearing Day")
    dropdowns = page.all(".Select-control")
    dropdowns[2].click
    expect do
      dropdowns[2].sibling(".Select-menu-outer").find("div .Select-option",
                                                      text: "#{coordinator.snamef} #{coordinator.snamel}").click
    end.to raise_error(Capybara::ElementNotFound)
    find("label[for=coordinatorEdit]").click
    dropdowns[2].click
    dropdowns[2].sibling(".Select-menu-outer").find("div .Select-option",
                                                    text: "#{coordinator.snamef} #{coordinator.snamel}").click
    find("button", text: "Confirm").click
    expect(page).to have_content("You have successfully completed this action")
  end

  scenario "first option is 'None'" do
    visit "hearings/schedule"
    find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click
    find("button", text: "Edit Hearing Day").click
    find("label[for=roomEdit]").click
    click_dropdown(name: "room", index: 0)
    expect(dropdown_selected_value(find(".dropdown-room"))).to eq "None"
  end
end
