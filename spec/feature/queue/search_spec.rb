require "rails_helper"

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
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
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
          let!(:veteran) { FactoryBot.create(:veteran) }
          let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: veteran.file_number) }

          before do
            visit "/search"
            fill_in "searchBarEmptyList", with: higher_level_review.veteran_file_number
            click_on "Search"
          end

          it "should show the HLR / SCs table" do
            expect(page).to have_content(COPY::CASE_LIST_TABLE_EMPTY_TEXT)
            expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
          end
        end

        context "and it also has appeals" do
          let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: appeal.veteran_file_number) }
          let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: appeal.veteran_file_number) }
          let!(:eligible_request_issue) { create(:request_issue, review_request: higher_level_review) }

          before do
            visit "/search"
            fill_in "searchBarEmptyList", with: appeal.sanitized_vbms_id
            click_on "Search"
          end

          context "has a higher level review" do
            it "shows the HLR / SCs table" do
              expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
            end

            it "shows a higher level review" do
              expect(find(".cf-other-reviews-table > tbody")).to have_content("Higher Level Review")
            end

            context "and has no end products" do
              it "shows no end products" do
                expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
                expect(find(".cf-other-reviews-table > tbody")).to have_content(COPY::OTHER_REVIEWS_TABLE_NO_EPS_NOTE)
              end
            end

            context "and has end products" do
              let!(:end_product_establishment_1) do
                create(
                  :end_product_establishment,
                  source: higher_level_review,
                  veteran_file_number: appeal.veteran_file_number,
                  synced_status: "CAN"
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

              context "when the EPs have not been established" do
                it "shows that the EP is establishing if it has not been established" do
                  expect(find(".cf-other-reviews-table > tbody")).to have_content(COPY::OTHER_REVIEWS_TABLE_ESTABLISHING)
                  expect(find(".cf-other-reviews-table > tbody")).to_not have_content("Canceled")
                  expect(find(".cf-other-reviews-table > tbody")).to_not have_content("Cleared")
                end
              end

              context "if there was an establishment error" do
                before do
                  higher_level_review.establishment_error = "big error"
                  higher_level_review.establish!
                end

                it "shows that the EP has an establishment error" do
                  expect(find(".cf-other-reviews-table > tbody")).to have_content(COPY::OTHER_REVIEWS_TABLE_ESTABLISHMENT_FAILED)
                end
              end

              context "the EP has been established" do
                before do
                  end_product_establishment_1.commit!
                  end_product_establishment_2.commit!
                  end_product_establishment_3.commit!
                  higher_level_review.establish!
                end

                it "shows the end product status" do
                  expect(find(".cf-other-reviews-table > tbody")).to have_content("Canceled")
                  expect(find(".cf-other-reviews-table > tbody")).to have_content("Cleared")
                end

                it "if the end products have synced_status codes we don't recognize, show the status code" do
                  expect(find(".cf-other-reviews-table > tbody")).to have_content("LOL")
                end
              end
            end
          end

          context "has a supplemental claim" do
            it "shows the HLR / SCs table" do
              expect(page).to have_content(COPY::OTHER_REVIEWS_TABLE_TITLE)
            end

            it "shows a supplemental claim and that it's 'tracked in caseflow'" do
              expect(find(".cf-other-reviews-table > tbody")).to have_content(
                COPY::OTHER_REVIEWS_TABLE_SUPPLEMENTAL_CLAIM_NOTE
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
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "searching in search bar produces another error" do
        fill_in "searchBarEmptyList", with: veteran_with_no_appeals.file_number
        click_on "Search"

        expect(page).to have_content(
          format(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_with_no_appeals.file_number)
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
        find("a", exact_text: appeal.docket_number).click
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
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_INVALID_ID_HEADING, invalid_veteran_id))
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
          format(COPY::CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, veteran_with_no_appeals.file_number)
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
        expect(page).to have_content(format(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, appeal.sanitized_vbms_id))
      end

      it "searching in search bar works" do
        fill_in "searchBarEmptyList", with: veteran_with_no_appeals.file_number
        click_on "Search"
        expect(page).to have_content(
          format(COPY::CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, veteran_with_no_appeals.file_number)
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
