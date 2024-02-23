# frozen_string_literal: true

RSpec.feature "List Schedule for Hearing Prep", :all_dbs do
  let!(:current_user) { User.authenticate!(css_id: "BVATWARNER", roles: ["Hearing Prep"]) }

  context "Correct buttons are displayed" do
    let!(:hearing) { create(:hearing) }

    scenario "No buttons are visible" do
      visit "hearings/schedule"
      expect(page).to have_content(COPY::HEARING_SCHEDULE_JUDGE_DEFAULT_VIEW_PAGE_HEADER)
      expect(page).to_not have_content("Schedule Veterans")
      expect(page).to_not have_content("Build Schedule")
      expect(page).to_not have_content("Add Hearing Day")
    end
  end

  context "Judge view" do
    context "No hearing day or hearings assigned to judge" do
      let!(:hearing_day) { create(:hearing_day) }

      scenario "Correct hearing days are displayed" do
        visit "hearings/schedule"

        expect(page).to_not have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Hearing day assigned to judge" do
      let!(:hearing_day) { create(:hearing_day, judge: current_user) }

      scenario "Correct hearing days are displayed" do
        visit "hearings/schedule"
        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Hearing day assigned to different judge with one legacy hearing assigned to judge" do
      let!(:hearing_day) { create(:hearing_day) }
      let!(:vacols_staff) { create(:staff, user: current_user) }
      let!(:case_hearing) { create(:case_hearing, vdkey: hearing_day.id, board_member: vacols_staff.sattyid) }

      scenario "Correct hearing days are displayed" do
        visit "hearings/schedule"

        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Hearing day assigned to different judge with one AMA hearing assigned to judge" do
      let!(:hearing_day) { create(:hearing_day) }
      let!(:hearing) { create(:hearing, :with_tasks, hearing_day: hearing_day) }

      scenario "Correct hearing days are displayed" do
        hearing.update!(judge: current_user)
        visit "hearings/schedule"

        expect(page).to have_content(Hearing::HEARING_TYPES[HearingDay.first.request_type.to_sym])
      end
    end

    context "Many hearing days assigned to judge and not assigned to judge" do
      before do
        5.times do
          create(:hearing, :with_tasks, judge: current_user, regional_office: "RO13")
        end
        5.times do
          create(:hearing, :with_tasks)
        end
      end

      scenario "Can switch to tab to see all hearing days" do
        visit "hearings/schedule"

        expect(page).to have_css(".section-hearings-list tbody tr", count: 5)
        find(".cf-dropdown-trigger", text: "Switch View").click
        find("li", text: "Complete Hearing Schedule").click
        expect(page).to have_css(".section-hearings-list tbody tr", count: 10)
      end
      it "Can filter hearings by type" do
        visit "hearings/schedule"

        find(".section-hearings-list .table-icon", class: "unselected-filter-icon", match: :first).click
        expect(page).to have_css(".cf-filter-option-row")
        find(".cf-filter-option-row", text: "Video").click
        expect(page).to_not have_content("Central")
      end
    end
  end
  context "Hearing prep deprecation" do
    let!(:current_user) { User.authenticate!(roles: ["Hearing Prep"]) }

    scenario "Upcoming docket days redirects to hearing schedule" do
      visit "/hearings/dockets"
      expect(page.current_path).to eq("/hearings/schedule")
    end
  end
end
