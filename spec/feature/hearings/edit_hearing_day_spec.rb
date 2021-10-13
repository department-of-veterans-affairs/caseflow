# frozen_string_literal: true

RSpec.feature "Edit a Hearing Day", :all_dbs do
  let!(:current_user) do
    user = create(:user, css_id: "BVATWARNER", roles: ["Build HearSched"])
    HearingsManagement.singleton.add_user(user)
    User.authenticate!(user: user)
  end

  let!(:judge) do
    create(:staff, :judge_role, sdomainid: "BVAAABSHIRE", snamel: "Abshire", snamef: "Judge")
    create(:user, css_id: "BVAAABSHIRE", full_name: "Judge Abshire")
  end

  let!(:update_judge) do
    create(:staff, :judge_role, sdomainid: "BVANNEWJUDGE", snamel: "NewJudge", snamef: "New")
    create(:user, css_id: "BVANNEWJUDGE", full_name: "Judge NewJudge")
  end

  let!(:coordinator) do
    create(:staff, :hearing_coordinator)
  end
  let(:sample_notes) { "Some example notes" }
  let!(:caseflow_coordinator) do
    User.find_by_css_id_or_create_with_default_station_id(coordinator.sdomainid)
  end

  before do
    HearingsManagement.singleton.add_user(caseflow_coordinator)
  end

  def navigate_to_docket(hearings = false)
    visit "hearings/schedule"
    find_link(hearing_day.scheduled_for.strftime("%a %-m/%d/%Y")).click

    if hearings == false
      expect(page).to have_content("Edit Hearing Day")
      expect(page).to have_content("No Veterans are scheduled for this hearing day.")
    end

    find("button", text: "Edit Hearing Day").click
  end

  shared_examples "always editable fields" do
    before do
      navigate_to_docket
    end

    it "displays initial fields when page is loaded", :aggregate_failures do
      expect(page).to have_field("hearingDate", disabled: true)
      expect(page).to have_content("Edit Hearing Day")
      expect(page).to have_content("Select VLJ")
      expect(page).to have_content("Select Hearing Coordinator")
      expect(page).to have_content("Notes")
    end

    it "can make changes to the VLJ on the docket" do
      click_dropdown(name: "vlj", index: 1, wait: 30)
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.judge_id).to eq(update_judge.id)
    end

    it "can make changes to the Coordinator on the docket" do
      click_dropdown(name: "coordinator", index: 0)
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(page).to have_content("#{coordinator.snamef} #{coordinator.snamel}")
    end

    it "can make changes to the Notes on the docket" do
      find("textarea", id: "Notes").fill_in(with: sample_notes)
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.notes).to eq(sample_notes)
      expect(page).to have_content(sample_notes)
    end
  end

  context "when request type is 'Central'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "C", room: "2", judge_id: judge.id)
    end

    include_examples "always editable fields"
  end

  context "when request type is 'Virtual'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "R", regional_office: nil, room: "", judge_id: judge.id)
    end

    include_examples "always editable fields"

    scenario "Time slot preview shown by default" do
      navigate_to_docket
    end
  end

  context "when request type is 'Video'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "V", room: "2", judge_id: judge.id, regional_office: "RO17")
    end

    include_examples "always editable fields"

    scenario "cannot change regional office" do
    end
  end

  context "when request type is 'Travel'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "T", room: "2", judge_id: judge.id)
    end

    include_examples "always editable fields"
  end

  context "when hearings have already been scheduled" do
    let!(:hearings) do
      [
        create(:hearing, regional_office: "RO62", hearing_day: hearing_day, scheduled_time: "11:30AM")
      ]
    end

    scenario "cannot change docket type" do
      navigate_to_docket

      expect(page).to have_field("requestType", disabled: true)
    end
  end
end
