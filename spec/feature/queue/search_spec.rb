require "rails_helper"
# rubocop:disable Style/FormatString

RSpec.feature "Search" do
  let(:attorney_user) { FactoryBot.create(:user) }
  let!(:vacols_atty) { FactoryBot.create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }
  let(:veteran_with_no_appeals) { FactoryBot.create(:veteran) }
  let!(:appeal) { FactoryBot.create(:legacy_appeal, :with_veteran, vacols_case: FactoryBot.create(:case)) }

  before do
    User.authenticate!(user: attorney_user)
  end

  context "queue case search for appeals using veteran id" do
    context "when invalid Veteran ID input" do
      before do
        visit "/search"
        fill_in "searchBarEmptyList", with: invalid_veteran_id
        click_on "Search"
      end

      it "page displays invalid Veteran ID message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to_not have_content("1 case found for")
      end
    end

    context "queue case search for appeals that have hearings" do
      context "a case in the search view has a hearing" do
        let!(:today) { Time.zone.today }
        let!(:hearings) do
          [
            create(:case_hearing, :disposition_held, hearing_date: today - 4.days),
            create(:case_hearing, :disposition_no_show, hearing_date: today - 3.days),
            create(:case_hearing, :disposition_postponed, hearing_date: today - 2.days)
          ]
        end

        let!(:appeal_with_hearing) do
          FactoryBot.create(
            :legacy_appeal,
            :with_veteran,
            vacols_case: FactoryBot.create(
              :case,
              case_hearings: hearings
            )
          )
        end

        before do
          visit "/search"
          fill_in "searchBarEmptyList", with: appeal_with_hearing.sanitized_vbms_id
          click_on "Search"
        end

        it "table row displays a badge if a case has a hearing" do
          expect(page).to have_selector(".cf-hearing-badge")
          expect(find(".cf-hearing-badge")).to have_content("H")
        end

        it "shows information for the correct hearing when there are multiple hearings" do
          expect(page).to have_css(
            ".__react_component_tooltip div ul li:nth-child(3) strong span",
            visible: :hidden,
            text: 2.days.ago.strftime("%m/%d/%y")
          )
        end
      end

      context "no cases in the search view have hearings" do
        before do
          visit "/search"
          fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
          click_on "Search"
        end

        it "table does not display a column for a badge if no cases have hearings" do
          docket_column_header = page.find(:xpath, "//thead/tr/th[1]/span")
          expect(docket_column_header).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
        end
      end
    end

    context "when no appeals found" do
      before do
        visit "/search"
        fill_in "searchBarEmptyList", with: veteran_with_no_appeals.file_number
        click_on "Search"
      end

      it "page displays no cases found message" do
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_with_no_appeals.file_number)
        )
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to_not have_content("1 case found for")
      end
    end

    context "when backend encounters an error" do
      before do
        allow(LegacyAppeal).to receive(:fetch_appeals_by_file_number).and_raise(StandardError)
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "displays error message on same page" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "searching in search bar produces another error" do
        fill_in "searchBarEmptyList", with: veteran_with_no_appeals.file_number
        click_on "Search"

        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_with_no_appeals.file_number)
        )
      end
    end

    context "when one appeal found" do
      let!(:paper_appeal) do
        FactoryBot.create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: FactoryBot.create(
            :case,
            folder: FactoryBot.build(:folder, :paper_case)
          )
        )
      end

      before do
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "page displays table of results" do
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "search bar stays in top right" do
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "clicking on the x in the search bar clears the search bar" do
        click_on "button-clear-search"
        expect(find("#searchBarEmptyList")).to have_content("")
      end

      it "clicking on docket number sends us to the case details page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")
        expect(page).not_to have_content "Select an action"
      end

      scenario "found appeal is paper case" do
        visit "/search"
        fill_in "searchBarEmptyList", with: paper_appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::IS_PAPER_CASE)
      end
    end
  end

  context "case search from home page" do
    let(:search_homepage_title) { COPY::CASE_SEARCH_HOME_PAGE_HEADING }
    let(:search_homepage_subtitle) { COPY::CASE_SEARCH_INPUT_INSTRUCTION }

    let(:non_queue_user) { FactoryBot.create(:user) }

    before do
      FeatureToggle.enable!(:case_search_home_page)
      User.authenticate!(user: non_queue_user)
    end

    after do
      FeatureToggle.disable!(:case_search_home_page)
    end

    scenario "logo links to / instead of /queue" do
      visit "/"
      have_link("Caseflow", href: "/")
    end

    context "when invalid Veteran ID input" do
      before do
        visit "/search"
        fill_in "searchBarEmptyList", with: invalid_veteran_id
        click_on "Search"
      end

      it "page displays invalid Veteran ID message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when no appeals found" do
      before do
        visit "/search"
        fill_in "searchBarEmptyList", with: veteran_with_no_appeals.file_number
        click_on "Search"
      end

      it "page displays no cases found message" do
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_with_no_appeals.file_number)
        )
      end

      it "search bar appears at top of page" do
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when backend encounters an error" do
      before do
        allow(LegacyAppeal).to receive(:fetch_appeals_by_file_number).and_raise(StandardError)
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "displays error message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: veteran_with_no_appeals.file_number
        click_on "Search"
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_with_no_appeals.file_number)
        )
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when one appeal found" do
      before do
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "page displays table of results" do
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "search bar displayed at top of page" do
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "clicking on docket number sends us to the case details page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")
      end
    end
  end
end

# rubocop:enable Style/FormatString
