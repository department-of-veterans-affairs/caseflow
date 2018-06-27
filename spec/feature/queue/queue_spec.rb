require "rails_helper"
# rubocop:disable Style/FormatString

RSpec.feature "Queue" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
    FeatureToggle.disable!(:queue_phase_two)
  end

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
        description: Generators::Random.word_characters(50)
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
  let(:vacols_record) { :remand_decided }
  let(:appeals) do
    [
      Generators::LegacyAppeal.build(
        vbms_id: "123456789S",
        vacols_record: vacols_record,
        documents: documents
      ),
      Generators::LegacyAppeal.build(
        vbms_id: "115555555S",
        vacols_record: vacols_record,
        documents: documents,
        issues: []
      )
    ]
  end
  let!(:issues) { [Generators::Issue.build] }
  let! :attorney_user do
    User.authenticate!(roles: ["System Admin"])
  end

  let!(:vacols_tasks) { Fakes::QueueRepository.tasks_for_user(attorney_user.css_id) }
  let!(:vacols_appeals) { Fakes::QueueRepository.appeals_from_tasks(vacols_tasks) }

  context "queue case search for appeals using veteran id" do
    let(:appeal) { appeals.first }
    let!(:veteran_id_with_no_appeals) { Generators::Random.unique_ssn }
    let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }

    context "when invalid Veteran ID input" do
      before do
        visit "/queue"
        fill_in "searchBar", with: invalid_veteran_id
        click_on "Search"
      end

      it "page displays invalid Veteran ID message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "searching in search bar works" do
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      end
    end

    context "when no appeals found" do
      before do
        visit "/queue"
        fill_in "searchBar", with: veteran_id_with_no_appeals
        click_on "Search"
      end

      it "page displays no cases found message" do
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_id_with_no_appeals)
        )
      end

      it "searching in search bar works" do
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      end
    end

    context "when backend encounters an error" do
      before do
        allow(LegacyAppeal).to receive(:fetch_appeals_by_file_number).and_raise(StandardError)
        visit "/queue"
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "displays error message on same page" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "searching in search bar produces another error" do
        fill_in "searchBar", with: veteran_id_with_no_appeals
        click_on "Search"

        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_id_with_no_appeals))
      end
    end

    context "when one appeal found" do
      before do
        visit "/queue"
        fill_in "searchBar", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "page displays table of results" do
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "search bar stays in top right" do
        expect(page).to have_selector("#searchBar")
      end

      it "clicking on the x in the search bar clears the search bar" do
        click_on "button-clear-search"
        expect(find("#searchBar")).to have_content("")
      end

      it "clicking on docket number sends us to the case details page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")

        expect(page).not_to have_content "Select an action"
      end

      scenario "found appeal is paper case" do
        visit "/queue"
        fill_in "searchBar", with: "384920173S"
        click_on "Search"

        expect(page).to have_content("1 case found for “Polly A Carter (384920173)”")
        expect(page).to have_content(COPY::IS_PAPER_CASE)
      end
    end
  end

  context "case search from home page" do
    let(:appeal) { appeals.first }
    let!(:veteran_id_with_no_appeals) { Generators::Random.unique_ssn }
    let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }
    let(:search_homepage_title) { COPY::CASE_SEARCH_HOME_PAGE_HEADING }
    let(:search_homepage_subtitle) { COPY::CASE_SEARCH_INPUT_INSTRUCTION }

    before do
      User.unauthenticate!
      User.authenticate!(css_id: "BVAAABSHIRE")
      FeatureToggle.enable!(:case_search_home_page)
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
        visit "/"
        fill_in "searchBarEmptyList", with: invalid_veteran_id
        click_on "Search"
      end

      it "page displays invalid Veteran ID message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "search bar does not appear in top right of page" do
        expect(page).to_not have_selector("#searchBar")
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

    context "when no appeals found" do
      before do
        visit "/"
        fill_in "searchBarEmptyList", with: veteran_id_with_no_appeals
        click_on "Search"
      end

      it "page displays no cases found message" do
        expect(page).to have_content(
          sprintf(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_id_with_no_appeals)
        )
      end

      it "search bar does not appear in top right of page" do
        expect(page).to_not have_selector("#searchBar")
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
        visit "/"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "displays error message" do
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "search bar does not appear in top right of page" do
        expect(page).to_not have_selector("#searchBar")
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: veteran_id_with_no_appeals
        click_on "Search"
        expect(page).to have_content(sprintf(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_id_with_no_appeals))
      end

      it "clicking on the x in the search bar returns browser to queue list page" do
        click_on "button-clear-search"
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
      end
    end

    context "when one appeal found" do
      before do
        visit "/"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      it "page displays table of results" do
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "search bar displayed in top right of page" do
        expect(page).to have_selector("#searchBar")
        expect(page).to_not have_selector("#searchBarEmptyList")
      end

      it "clicking on docket number sends us to the case details page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")
      end

      it "clicking on back breadcrumb from detail view sends us to search results page" do
        click_on appeal.docket_number
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")

        click_on sprintf(COPY::BACK_TO_SEARCH_RESULTS_LINK_LABEL, appeal.veteran_full_name)
        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
        expect(page.current_path).to match(/^\/cases\/\d+$/)
      end

      it "clicking on back breadcrumb sends us to empty search home page", skip: "the test is non-deterministic" do
        page.find("h1").find("a").click
        expect(page).to have_content(search_homepage_title)
        expect(page).to have_content(search_homepage_subtitle)
        expect(page.current_path).to eq("/")
      end
    end
  end

  context "loads queue table view" do
    scenario "table renders row per task" do
      visit "/queue"

      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)

      vet_not_appellant = vacols_appeals.reject { |a| a.appellant_first_name.nil? }.first
      vna_appeal_row = find("tbody").find("#table-row-#{vet_not_appellant.vacols_id}")
      first_cell = vna_appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{vet_not_appellant.veteran_full_name} (#{vet_not_appellant.vbms_id})")
      expect(first_cell).to have_content(COPY::CASE_DIFF_VETERAN_AND_APPELLANT)

      paper_case = vacols_appeals.select { |a| a.file_type.eql? "Paper" }.first
      pc_appeal_row = find("tbody").find("#table-row-#{paper_case.vacols_id}")
      first_cell = pc_appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{paper_case.veteran_full_name} (#{paper_case.vbms_id.delete('S')})")
      expect(first_cell).to have_content(COPY::IS_PAPER_CASE)
    end
  end

  context "loads attorney task detail views" do
    before do
      User.unauthenticate!
      User.authenticate!(roles: ["System Admin"])
    end

    context "loads appeal summary view" do
      scenario "appeal has hearing" do
        appeal = vacols_appeals.reject { |a| a.hearings.empty? }.first
        hearing = appeal.hearings.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Select an action")

        hearing_preference = hearing.type.to_s.split("_").map(&:capitalize).join(" ")
        expect(page).to have_content("Type: #{hearing_preference}")

        if hearing.disposition.eql? :cancelled
          expect(page).to have_content("Disposition: Cancelled")
        else
          expect(page).to have_content("Date: #{hearing.date.strftime('%-m/%-e/%y')}")
          expect(page).to have_content("Judge: #{hearing.user.full_name}")

          unless hearing.hearing_views.empty?
            worksheet_link = page.find("a[href='/hearings/#{hearing.id}/worksheet/print']")
            expect(worksheet_link.text).to eq("View Hearing Worksheet")
          end
        end
      end

      scenario "appeal has no hearing" do
        task = vacols_tasks.select { |t| t.hearings.empty? }.first
        appeal = vacols_appeals.select { |a| a.vacols_id.eql? task.vacols_id }.first
        appeal_ro = appeal.regional_office

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).not_to have_content("Hearing preference")

        expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_ABOUT_BOX_TYPE_LABEL} CAVC/i)
        expect(page).to have_content("Power of Attorney")
        expect(page).to have_content(appeal.representative)
        expect(page).to have_content("Regional Office: #{appeal_ro.city} (#{appeal_ro.key.sub('RO', '')})")
      end
    end

    context "loads appellant detail view" do
      scenario "veteran is the appellant" do
        appeal = vacols_appeals.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Veteran Details")
        expect(page).to have_content("The veteran is the appellant.")

        expect(page).to have_content("She/Her")
        # rubocop:disable Style/FormatStringToken
        expect(page).to have_content(appeal.veteran_date_of_birth.strftime("%-m/%e/%Y"))
        # rubocop:enable Style/FormatStringToken
        expect(page).to have_content("The veteran is the appellant.")
      end

      scenario "veteran is not the appellant" do
        appeal = vacols_appeals.reject { |a| a.appellant_name.nil? }.first

        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        expect(page).to have_content("Appellant Details")
        expect(page).to have_content("Veteran Details")
        expect(page).to have_content(COPY::CASE_DIFF_VETERAN_AND_APPELLANT)

        expect(page).to have_content(appeal.appellant_name)
        expect(page).to have_content(appeal.appellant_relationship)
        expect(page).to have_content(appeal.appellant_address_line_1)
      end
    end

    context "links to reader" do
      scenario "from appellant details page" do
        appeal = vacols_appeals.first
        visit "/queue"

        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"

        sleep 1
        expect(page).to have_content("Your Queue > #{appeal.veteran_full_name}")

        click_on "View #{appeal.documents.count} documents"

        # ["Caseflow", "> Reader"] are two elements, space handled by margin-left on second
        expect(page).to have_content("Caseflow> Reader")
        expect(page).to have_content("Back to #{appeal.veteran_full_name} (#{appeal.vbms_id})")

        click_on "Caseflow"
        expect(page.current_path).to eq "/queue"
      end
    end

    context "displays issue dispositions" do
      scenario "from appellant details page" do
        appeal = vacols_appeals.first
        visit "/queue"
        click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
        expect(page).to have_content("Disposition: 1 - Allowed")
      end
    end
  end

  context "loads judge task detail views" do
    before do
      User.unauthenticate!
      User.authenticate!(css_id: "BVAAABSHIRE")
      FeatureToggle.enable!(:judge_queue)
    end

    after do
      FeatureToggle.disable!(:judge_queue)
      User.unauthenticate!
      User.authenticate!
    end

    scenario "displays who prepared task" do
      vacols_tasks = Fakes::QueueRepository.tasks_for_user current_user.css_id

      task = vacols_tasks.select { |a| a.assigned_by.first_name.present? }.first
      visit "/queue"

      click_on "#{task.veteran_full_name} (#{task.vbms_id})"

      preparer_name = "#{task.assigned_by.first_name[0]}. #{task.assigned_by.last_name}"
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_PREPARER_LABEL} #{preparer_name}/i)
      expect(page.document.text).to match(/#{COPY::CASE_SNAPSHOT_DECISION_DOCUMENT_ID_LABEL} #{task.document_id}/i)
    end
  end

  context "pop breadcrumb" do
    scenario "goes back from submit decision view" do
      appeal = vacols_appeals.select { |a| a.issues.map(&:disposition).uniq.eql? [nil] }.first
      visit "/queue"

      click_on "#{appeal.veteran_full_name} (#{appeal.vbms_id})"
      sleep 1
      safe_click(".Select-control")
      safe_click("div[id$='--option-0']")

      issue_rows = page.find_all("tr[id^='table-row-']")
      expect(issue_rows.length).to eq(appeal.issues.length)

      issue_rows.each do |row|
        row.find(".Select-control").click
        row.find("div[id$='--option-2']").click
      end

      click_on "Continue"

      expect(page).to have_content("Submit Draft Decision for Review")
      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions > Submit")

      click_on "Back"

      expect(page).to have_content("Your Queue > #{appeal.veteran_full_name} > Select Dispositions")
      expect(page).not_to have_content("Select Dispositions > Submit")
    end
  end
end

# rubocop:enable Style/FormatString
