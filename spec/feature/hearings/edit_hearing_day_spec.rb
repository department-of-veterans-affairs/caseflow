# frozen_string_literal: true

RSpec.feature "Edit a Hearing Day", :all_dbs do
  let(:sample_notes) { "Some example notes" }
  let(:default_slot_length) { "30 minutes" }
  let(:default_num_slots) { 4 }
  let(:default_start_time) { "8:45 AM" }
  let(:sample_room) { "1 (1W200A)" }

  let!(:current_user) do
    user = create(:user, css_id: "EDITHEARINGDAY", roles: ["Build HearSched"])
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
  let!(:caseflow_coordinator) do
    User.find_by_css_id_or_create_with_default_station_id(coordinator.sdomainid)
  end
  let!(:hearing_day) do
    create(:hearing_day, request_type: "C", room: "2", judge_id: judge.id)
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
      click_dropdown(name: "coordinator", text: "#{coordinator.snamef} #{coordinator.snamel}")
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(page).to have_content("#{coordinator.snamef} #{coordinator.snamel}")
      expect(hearing_day.reload.bva_poc).to eq("#{coordinator.snamef} #{coordinator.snamel}")
    end

    it "can make changes to the Notes on the docket" do
      find("textarea", id: "Notes").fill_in(with: sample_notes)
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.notes).to eq(sample_notes)
      expect(page).to have_content(sample_notes)
    end
  end

  shared_examples "edit room" do
    it "can make changes to the Room on the docket" do
      click_dropdown(name: "room", text: sample_room)
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.room).to eq(sample_room.first)
      expect(page).to have_content(sample_room)
    end

    it "can remove the Room from the docket" do
      click_dropdown(name: "room", text: "None")
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.room).to eq(nil)
    end
  end

  shared_examples "convert to virtual" do
    it "can convert docket type to virtual" do
      click_dropdown(name: "requestType", text: "Virtual")

      # If the docket Central, change the RO to prevent the error state
      if hearing_day.request_type == HearingDay::REQUEST_TYPES[:central]
        click_dropdown(name: "regionalOffice", index: 1)
      end

      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.request_type).to eq(HearingDay::REQUEST_TYPES[:virtual])
    end
  end

  shared_examples "edit virtual docket" do
    it "can edit virtual docket specific fields" do
      # If the docket is not already virtual, first convert it
      if hearing_day.request_type != HearingDay::REQUEST_TYPES[:virtual]
        click_dropdown(name: "requestType", text: "Virtual")
      end

      if hearing_day.request_type == HearingDay::REQUEST_TYPES[:central]
        click_dropdown(name: "regionalOffice", index: 1)
      end

      click_dropdown(name: "numberOfSlots", text: default_num_slots)
      click_dropdown(name: "slotLengthMinutes", text: default_slot_length)
      click_dropdown(name: "optionalHearingTime0", text: default_start_time)
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.slot_length_minutes).to eq(30)
      expect(hearing_day.reload.number_of_slots).to eq(default_num_slots)
      expect(hearing_day.reload.first_slot_time).to eq("08:45")
    end
  end

  shared_examples "edit hearing start time" do
    it "can edit hearing start time to full day" do
      # If the docket is not already video or travel, first convert it
      if hearing_day.request_type != HearingDay::REQUEST_TYPES[:video]
        click_dropdown(name: "requestType", text: "Video")
      end

      radio_choices = page.all(".cf-form-radio-option > label")
      radio_choices[0].click
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.first_slot_time).to eq(nil)
      expect(hearing_day.reload.total_slots).to eq(10)
    end

    it "can edit hearing start time to half day" do
      # If the docket is not already video or travel, first convert it
      if hearing_day.request_type != HearingDay::REQUEST_TYPES[:video] ||
         hearing_day.request_type != HearingDay::REQUEST_TYPES[:travel]
        click_dropdown(name: "requestType", text: "Video")
      end

      radio_choices = page.all(".cf-form-radio-option > label")
      radio_choices[1].click
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.first_slot_time).to eq("08:30")
      expect(hearing_day.reload.total_slots).to eq(5)
    end
  end

  context "when request type is 'Central'" do
    include_examples "always editable fields"
    include_examples "convert to virtual"
    include_examples "edit virtual docket"
    include_examples "edit room"

    it "requires changing the regional office when docket type is changed" do
      click_dropdown(name: "requestType", text: "Virtual")
      expect(page).to have_content(COPY::DOCKET_INVALID_RO_TYPE)

      # Ensure the change is not persisted
      find("button", text: "Save Changes").click
      expect(hearing_day.reload.request_type).to eq(HearingDay::REQUEST_TYPES[:central])
    end
  end

  context "when request type is 'Virtual'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "R", regional_office: "RO17", room: "", judge_id: judge.id)
    end

    include_examples "always editable fields"
    include_examples "edit virtual docket"

    it "form does not contain the room field" do
      expect(page).not_to have_field("Select Room")
    end

    it "can convert docket type" do
      click_dropdown(name: "requestType", text: "Central")
      find("button", text: "Save Changes").click

      expect(page).to have_content("You have successfully updated this hearing day.")
      expect(hearing_day.reload.request_type).to eq(HearingDay::REQUEST_TYPES[:central])
    end
  end

  context "when request type is 'Video'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "V", room: "2", judge_id: judge.id, regional_office: "RO17")
    end

    include_examples "always editable fields"
    include_examples "convert to virtual"
    include_examples "edit virtual docket"
    include_examples "edit room"
    include_examples "edit hearing start time"
  end

  context "when request type is 'Travel'" do
    let!(:hearing_day) do
      create(:hearing_day, request_type: "T", regional_office: "RO17", room: "2", judge_id: judge.id)
    end

    include_examples "always editable fields"
    include_examples "convert to virtual"
    include_examples "edit virtual docket"
    include_examples "edit room"
  end

  context "when hearings have already been scheduled" do
    let!(:hearings) do
      [
        create(:hearing, regional_office: "RO17", hearing_day: hearing_day, scheduled_time: "11:30AM")
      ]
    end

    scenario "cannot change docket type" do
      navigate_to_docket(hearings)

      expect(page).to have_field("Type of Docket", disabled: true, visible: false)
      expect(page).to have_content(COPY::DOCKET_HAS_HEARINGS_SCHEDULED)
    end
  end
end
