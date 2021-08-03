# frozen_string_literal: true

feature "Search", :all_dbs do
  let(:attorney_user) { create(:user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

  let(:invalid_veteran_id) { "obviouslyinvalidveteranid" }
  let(:invalid_docket_number) { "invaliddocket-number" }
  let(:veteran_with_no_appeals) { create(:veteran) }
  let!(:appeal) { create(:legacy_appeal, :with_veteran, vacols_case: create(:case)) }
  let!(:substitute_appeal) { create(:appellant_substitution) }

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
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id, fill_options: { clear: :backspace }
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar clears the search bar" do
        expect(page).to have_field("search", with: invalid_veteran_id)

        click_on "button-clear-search"

        expect(page).to_not have_field("search", with: invalid_veteran_id)
      end
    end

    context "higher level reviews and supplemental claims" do
      context "when a claim has no higher level review and/or supplemental claims" do
        before do
          visit "/search"
          fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
          click_on "Search"
        end

        it "does not show the HLR / SCs table" do
          expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_EMPTY_TEXT)
        end
      end

      context "when a claim has a higher level review and/or supplemental claim" do
        context "and it has no appeals" do
          let!(:veteran) { create(:veteran) }
          let!(:higher_level_review) do
            create(:higher_level_review, :processed, veteran_file_number: veteran.file_number)
          end
          let!(:intake_user) { create(:intake_user) }

          before do
            User.authenticate!(user: intake_user)
          end

          before do
            visit "/search"
            fill_in "searchBarEmptyList", with: higher_level_review.veteran_file_number
            click_on "Search"
          end

          it "should show the HLR / SCs table" do
            expect(page).to have_content(COPY::CASE_LIST_TABLE_EMPTY_TEXT)
            expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
          end

          it "should show the HLR / SCs receipt date" do
            expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_RECEIPT_DATE_COLUMN_TITLE)
            expect(higher_level_review.receipt_date.mdY).to_not be_nil
          end

          it "should show edit issues page" do
            expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
            new_window = window_opened_by { click_on("edit-issues") }
            within_window new_window do
              expect(page).to have_content("Edit Issues")
            end
          end
        end

        context "and it also has appeals" do
          let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: appeal.veteran_file_number) }
          let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number) }
          let!(:eligible_request_issue) { create(:request_issue, decision_review: higher_level_review) }

          def perform_search
            visit "/search"
            fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
            click_on "Search"
          end

          context "has a higher level review" do
            it "shows the HLR / SCs table" do
              perform_search
              expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
            end

            it "shows a higher level review" do
              perform_search
              expect(page).to have_css(".cf-other-reviews-table > tbody", text: "Higher Level Review")
            end

            context "and has no end products" do
              it "shows no end products" do
                perform_search
                expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
                expect(page).to have_css(".cf-other-reviews-table > tbody", text: COPY::OTHER_REVIEWS_TABLE_NO_EPS_NOTE)
              end
            end

            context "has removed decision reviews" do
              before do
                higher_level_review.request_issues.each(&:remove!)
              end

              let!(:caseflow_appeal) { create(:appeal, veteran: higher_level_review.veteran) }
              let!(:removed_request_issue) { create(:request_issue, :removed, decision_review: caseflow_appeal) }

              it "does show removed appeals but not removed decision reviews" do
                perform_search
                expect(page).to have_css(".cf-other-reviews-table > tbody", text: "Supplemental Claim")
                expect(page).to_not have_css(".cf-other-reviews-table > tbody", text: "Higher Level Review")
                expect(page).to have_css(".cf-case-list-table > tbody", text: "Original")
              end
            end

            context "and has end products" do
              let!(:end_product_establishment_1) do
                create(
                  :end_product_establishment,
                  source: higher_level_review,
                  veteran_file_number: appeal.veteran_file_number,
                  synced_status: "CAN",
                  code: "930AHDENLPMC"
                )
              end
              let!(:end_product_establishment_2) do
                create(
                  :end_product_establishment,
                  source: higher_level_review,
                  veteran_file_number: appeal.veteran_file_number,
                  synced_status: "CLR"
                )
              end
              let!(:end_product_establishment_3) do
                create(
                  :end_product_establishment,
                  source: higher_level_review,
                  veteran_file_number: appeal.veteran_file_number,
                  synced_status: "LOL"
                )
              end
              let!(:end_product_establishment_4) do
                create(
                  :end_product_establishment,
                  source: higher_level_review,
                  veteran_file_number: appeal.veteran_file_number,
                  synced_status: "RW"
                )
              end

              context "when the EPs have not been established" do
                it "shows that the EP is establishing if it has not been established" do
                  perform_search
                  expect(page).to have_css(
                    ".cf-other-reviews-table > tbody",
                    text: COPY::OTHER_REVIEWS_TABLE_ESTABLISHING
                  )
                  expect(page).to_not have_css(".cf-other-reviews-table > tbody", text: "Canceled")
                  expect(page).to_not have_css(".cf-other-reviews-table > tbody", text: "Cleared")
                  expect(page).to_not have_css(".cf-other-reviews-table > tbody", text: "Ready to work")
                end
              end

              context "if there was an establishment error" do
                let!(:higher_level_review) do
                  create(:higher_level_review,
                         veteran_file_number: appeal.veteran_file_number,
                         establishment_error: "error")
                end

                it "shows that the EP has an establishment error" do
                  perform_search
                  expect(page).to have_css(
                    ".cf-other-reviews-table > tbody",
                    text: COPY::OTHER_REVIEWS_TABLE_ESTABLISHMENT_FAILED
                  )
                end
              end

              context "the EP has been established" do
                before do
                  higher_level_review.reload.establish!
                  end_product_establishment_1.commit!
                  end_product_establishment_2.commit!
                end

                it "shows the end product status" do
                  perform_search
                  expect(page).to have_content("030 Higher-Level Review Rating")
                  expect(page).to have_css(".cf-other-reviews-table > tbody", text: "Canceled")
                  expect(page).to have_css(".cf-other-reviews-table > tbody", text: "Cleared")
                  expect(page).to have_css(".cf-other-reviews-table > tbody", text: "Ready to work")
                end

                it "if the end products have synced_status codes we don't recognize, show the status code" do
                  perform_search
                  expect(page).to have_css(".cf-other-reviews-table > tbody", text: "LOL")
                end
              end
            end
          end

          context "has a supplemental claim" do
            it "shows the HLR / SCs table" do
              perform_search
              expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
            end

            it "shows a supplemental claim and that it's 'tracked in caseflow'" do
              perform_search
              expect(page).to have_css(
                ".cf-other-reviews-table > tbody",
                text: COPY::OTHER_REVIEWS_TABLE_SUPPLEMENTAL_CLAIM_NOTE
              )
            end
          end
        end
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
          create(
            :legacy_appeal,
            :with_veteran,
            vacols_case: create(
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
          expect(page).to have_css(".cf-hearing-badge", text: "H")
        end

        it "shows information for the most recently held hearing" do
          expect(page).to have_css(
            ".__react_component_tooltip div ul li:nth-child(3) strong span",
            visible: :hidden,
            text: 4.days.ago.strftime("%m/%d/%y")
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
          docket_column_header = find("table.cf-case-list-table > thead > tr > th:first-child > span")
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
          format(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_with_no_appeals.file_number)
        )
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id, fill_options: { clear: :backspace }
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end

      it "clicking on the x in the search bar clears the search bar" do
        expect(page).to have_field("search", with: veteran_with_no_appeals.file_number)

        click_on "button-clear-search"

        expect(page).to_not have_field("search", with: veteran_with_no_appeals.file_number)
      end
    end

    context "BGS can_access? is false" do
      before do
        Fakes::BGSService.new.bust_can_access_cache(user, appeal.sanitized_vbms_id)
        Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.sanitized_vbms_id]
        User.authenticate!(user: user)
      end

      let(:user) { create(:user) }

      def perform_search
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"
      end

      context "when user is VSO employee" do
        let(:user) { create(:user, :vso_role, css_id: "BVA_VSO") }

        it "displays a helpful error message on same page" do
          perform_search
          expect(page).to have_content("You do not have access to this claims file number")
        end
      end

      context "when user is BVA (not VSO) employee" do
        let(:user) { create(:user, :judge) }

        it "displays 1 result but clicking through gives permission denied" do
          perform_search
          expect(page).to have_content("1 case found")

          visit "/queue/appeals/#{appeal.vacols_id}"
          expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
        end
      end
    end

    context "when VSO employee searches for file number that does not match any veteran" do
      it "displays a helpful error message on same page" do
        vso_user = create(:user, :vso_role, css_id: "BVA_VSO")
        User.authenticate!(user: vso_user)
        visit "/search"
        fill_in "searchBarEmptyList", with: "666660000"
        click_on "Search"

        expect(page).to have_content("Could not find a Veteran matching the file number")
      end
    end

    context "when one appeal found" do
      let!(:paper_appeal) do
        create(
          :legacy_appeal,
          :with_veteran,
          vacols_case: create(
            :case,
            folder: build(:folder, :paper_case)
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
        expect(page).to have_css("#searchBarEmptyList", text: "")
      end

      it "clicking on docket number sends us to the case details page" do
        find("a", exact_text: appeal.docket_number).click
        expect(page.current_path).to eq("/queue/appeals/#{appeal.vacols_id}")
        expect(page.has_no_content?("Select an action")).to eq(true)
      end

      scenario "found appeal is paper case" do
        visit "/search"
        fill_in "searchBarEmptyList", with: paper_appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::IS_PAPER_CASE)
      end
    end

    context "when appeal is associated with ssn not file number" do
      let!(:veteran) { create(:veteran, file_number: "00000000", ssn: Generators::Random.unique_ssn) }
      let!(:legacy_appeal) do
        create(
          :legacy_appeal,
          vacols_case: create(:case, bfcorlid: "#{veteran.ssn}S")
        )
      end
      scenario "found one appeal" do
        visit "/search"
        fill_in "searchBarEmptyList", with: veteran.file_number
        click_on "Search"

        expect(page).to have_content("1 case found for")
      end
    end
  end

  context "queue case search for appeals using docket number" do
    let!(:veteran) { create(:veteran, first_name: "Testy", last_name: "McTesterson") }
    let!(:appeal) { create(:appeal, veteran: veteran) }

    def perform_search(search_term)
      visit "/search"
      fill_in "searchBarEmptyList", with: search_term
      click_on "Search"
    end

    context "when using invalid docket number" do
      it "page displays invalid search message" do
        perform_search(invalid_docket_number)
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_docket_number))
      end
    end

    context "when appeal exists" do
      it "displays correct single result" do
        perform_search(appeal.docket_number)

        expect(page).to have_content("1 case found for")
        expect(page).to have_content(COPY::CASE_LIST_TABLE_DOCKET_NUMBER_COLUMN_TITLE)
      end
    end

    context "when appeal doesn't exist" do
      let!(:non_existing_docket_number) { "010101-99999" }

      it "page displays no cases found message" do
        perform_search(non_existing_docket_number)
        expect(page).to have_content(
          format(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, non_existing_docket_number)
        )
      end
    end

    context "when BGS can_access? is false" do
      before do
        Fakes::BGSService.new.bust_can_access_cache(user, appeal.veteran_file_number)
        Fakes::BGSService.inaccessible_appeal_vbms_ids = [appeal.veteran_file_number]
        User.authenticate!(user: user)
      end

      let(:user) { create(:user) }

      def perform_search(docket_number = appeal.docket_number)
        visit "/search"
        fill_in "searchBarEmptyList", with: docket_number
        click_on "Search"
      end

      context "when user is VSO employee" do
        let(:user) { create(:user, :vso_role, css_id: "BVA_VSO") }

        it "displays a helpful error message on same page" do
          perform_search
          expect(page).to have_content("You do not have access to this claims file number")
        end

        context "when user represents substitute appellant" do
          it "does not short-circuit to the helpful error message" do
            perform_search(substitute_appeal)
            expect(page).not_to have_content("You do not have access to this claims file number")
          end
        end
      end

      context "when user is BVA (not VSO) employee" do
        let(:user) { create(:user, :judge) }

        it "displays 1 result but clicking through gives permission denied" do
          perform_search
          expect(page).to have_content("1 case found")

          visit "/queue/appeals/#{appeal.uuid}"
          expect(page).to have_content(COPY::ACCESS_DENIED_TITLE)
        end
      end
    end
  end

  context "case search from home page" do
    let(:search_homepage_title) { COPY::CASE_SEARCH_HOME_PAGE_HEADING }
    let(:search_homepage_subtitle) { COPY::CASE_SEARCH_INPUT_INSTRUCTION }

    let(:non_queue_user) { create(:user) }

    before do
      User.authenticate!(user: non_queue_user)
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
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id, fill_options: { clear: :backspace }
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
          format(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_with_no_appeals.file_number)
        )
      end

      it "search bar appears at top of page" do
        expect(page).to have_selector("#searchBarEmptyList")
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id, fill_options: { clear: :backspace }
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

    context "when backend returns non-serialized error" do
      it "displays generic server error message" do
        allow(LegacyAppeal).to receive(:fetch_appeals_by_file_number).and_raise(StandardError)
        visit "/search"
        fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
        click_on "Search"

        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
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

  def perform_search
    visit "/search"
    fill_in "searchBarEmptyList", with: caseflow_appeal.veteran_file_number
    click_on "Search"
  end

  context "has withdrawn decision reviews" do
    let!(:caseflow_appeal) { create(:appeal) }

    it "shows 'Withdrawn' text on search results page" do
      policy = instance_double(WithdrawnDecisionReviewPolicy)
      allow(WithdrawnDecisionReviewPolicy).to receive(:new).with(caseflow_appeal).and_return policy
      allow(policy).to receive(:satisfied?).and_return true
      perform_search

      expect(page).to have_content("Withdrawn")
    end
  end

  context "is cancelled ama appeal" do
    let!(:caseflow_appeal) { create(:appeal, :at_attorney_drafting, associated_attorney: attorney_user) }

    it "shows 'Cancelled' text on search results page" do
      perform_search
      expect(page).to have_content("Assigned To Attorney")
      expect(page).to have_content("Assigned to you")

      caseflow_appeal.reload.tasks.update_all(status: Constants.TASK_STATUSES.cancelled)
      perform_search
      expect(page).to have_content("Cancelled")
      expect(page).not_to have_content("Assigned to you")
    end
  end
end
