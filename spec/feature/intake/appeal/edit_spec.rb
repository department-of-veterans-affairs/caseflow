# frozen_string_literal: true

feature "Appeal Edit issues", :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    # skip the sync call since all edit requests require resyncing
    # currently, we're not mocking out vbms and bgs
    allow_any_instance_of(EndProductEstablishment).to receive(:sync!).and_return(nil)
    non_comp_org.add_user(current_user)
  end

  let(:veteran) do
    create(:veteran,
           first_name: "Ed",
           last_name: "Merica")
  end

  let!(:current_user) { User.authenticate!(roles: ["Mail Intake"]) }

  let!(:non_comp_org) { create(:business_line, name: "Non-Comp Org", url: "nco") }
  let(:last_week) { Time.zone.now - 7.days }
  let(:receipt_date) { Time.zone.today - 20.days }
  let(:profile_date) { (receipt_date - 30.days).to_datetime }

  let!(:rating) { generate_rating_with_defined_contention(veteran, receipt_date, profile_date) }
  let!(:rating_before_ama) { generate_pre_ama_rating(veteran) }
  let!(:rating_before_ama_from_ramp) { generate_rating_before_ama_from_ramp(veteran) }
  let!(:ratings_with_legacy_issues) do
    generate_rating_with_legacy_issues(veteran, receipt_date - 4.days, receipt_date - 4.days)
  end
  let(:request_issue_decision_mdY) { rating_request_issue.decision_or_promulgation_date.mdY }

  let(:legacy_opt_in_approved) { false }

  let!(:appeal) do
    create(:appeal,
           veteran_file_number: veteran.file_number,
           receipt_date: receipt_date,
           docket_type: Constants.AMA_DOCKETS.evidence_submission,
           veteran_is_not_claimant: false,
           legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
  end

  let!(:appeal2) do
    create(:appeal,
           veteran_file_number: veteran.file_number,
           receipt_date: receipt_date,
           docket_type: Constants.AMA_DOCKETS.evidence_submission,
           veteran_is_not_claimant: false,
           legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
  end

  let!(:appeal_intake) do
    create(:intake, user: current_user, detail: appeal, veteran_file_number: veteran.file_number)
  end

  let(:nonrating_request_issue_attributes) do
    {
      decision_review: appeal,
      nonrating_issue_category: "Military Retired Pay",
      nonrating_issue_description: "nonrating description",
      contention_reference_id: "1234",
      decision_date: 1.month.ago
    }
  end

  let!(:nonrating_request_issue) { create(:request_issue, nonrating_request_issue_attributes) }

  let(:rating_request_issue_attributes) do
    {
      decision_review: appeal,
      contested_rating_issue_reference_id: "def456",
      contested_rating_issue_profile_date: profile_date,
      contested_issue_description: "PTSD denied",
      contention_reference_id: "4567"
    }
  end

  let!(:rating_request_issue) { create(:request_issue, rating_request_issue_attributes) }

  # This veteran and appeal are a "blank canvas" with no request issues or pre-existing ratings/issues
  let(:vet_no_history) { create(:veteran) }
  let(:appeal3) do
    create(:appeal,
           veteran_file_number: vet_no_history.file_number,
           receipt_date: receipt_date,
           docket_type: Constants.AMA_DOCKETS.evidence_submission,
           veteran_is_not_claimant: false,
           legacy_opt_in_approved: legacy_opt_in_approved).tap(&:create_tasks_on_intake_success!)
  end

  scenario "Add, edit, and remove request issues" do
    step "allows adding/removing issues" do
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_content(nonrating_request_issue.description)

      # remove an issue
      click_remove_intake_issue_dropdown(nonrating_request_issue.description)
      expect(page.has_no_content?(nonrating_request_issue.description)).to eq(true)
      expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

      # add a different issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      # save flash should still occur because issues are different
      expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

      # save
      expect(page).to have_content("Left knee granted")
      safe_click("#button-submit-update")

      # should redirect to queue
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      expect(page).to have_content("added 1 issue")
      expect(page).to have_content("removed 1 issue")

      # going back to edit page should show those issues
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("Left knee granted")
      expect(page.has_no_content?("nonrating description")).to eq(true)

      # canceling should redirect to queue
      click_on "Cancel"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
    end

    step "allows removing and re-adding same issue" do
      issue_description = rating_request_issue.description

      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_content(issue_description)
      expect(page).to have_button("Save", disabled: true)
      # remove
      click_remove_intake_issue_dropdown(issue_description)
      expect(page.has_no_content?(issue_description)).to eq(true)
      expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

      # re-add
      click_intake_add_issue
      add_intake_rating_issue(issue_description, "a new comment")
      expect(page).to have_content(issue_description)
      expect(page).to_not have_content(
        Constants.INELIGIBLE_REQUEST_ISSUES.duplicate_of_rating_issue_in_active_review.gsub("{review_title}", "Appeal")
      )
      expect(page).to have_content("When you finish making changes, click \"Save\" to continue")

      # issue note was added
      expect(page).to have_button("Save", disabled: false)
    end

    step "when selecting a new benefit type the issue category dropdown should return to a default state" do
      visit "appeals/#{appeal3.uuid}/edit/"

      click_intake_add_issue

      dropdown_select_string = "Select or enter..."
      benefit_text = "Compensation"

      # Select the first benefit type
      all(".cf-select__control", text: dropdown_select_string).first.click
      find("div", class: "cf-select__option", text: benefit_text).click

      # Select the first issue category
      find(".cf-select__control", text: dropdown_select_string).click
      find("div", class: "cf-select__option", text: "Unknown Issue Category").click

      # Verify that the default dropdown text is missing from the page
      expect(page).to_not have_content(dropdown_select_string)

      # Select a different benefit type
      find(".cf-select__control", text: benefit_text).click
      find("div", class: "cf-select__option", text: "Education").click

      # Verify that the default dropdown text once again present on the page
      expect(page).to have_content(dropdown_select_string)
    end

    # this validates a bug fix from https://github.com/department-of-veterans-affairs/caseflow/pull/10197
    step "adding an issue with a non-comp benefit type returns to case details page" do
      visit "appeals/#{appeal.uuid}/edit/"

      # Add issue that is not a VBMS issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        benefit_type: "Education",
        category: "Accrued",
        description: "Description for Accrued",
        date: 1.day.ago.to_date.mdY
      )

      expect(page).to_not have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: false)

      click_edit_submit_and_confirm
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      page.find("a", text: "refresh the page").click if page.has_text?("Unable to load this case")
      expect(page).not_to have_content("Loading this case")
      expect(page).to have_content(veteran.name)
      expect(RequestIssue.find_by(
               benefit_type: "education",
               decision_review: appeal
             )).to_not be_nil
    end

    # originally added in https://github.com/department-of-veterans-affairs/caseflow/pull/10241
    step "allows all request issues to be removed and saved and cancels all active tasks" do
      visit "appeals/#{appeal.uuid}/edit/"

      # A VeteranRecordRequest task is added when the non-comp request issue is added. Complete it
      # to ensure that cancelling the appeal does not update its status to 'cancelled' later on
      appeal.tasks.where(type: VeteranRecordRequest.name).first.completed!

      # remove all issues
      click_remove_intake_issue_dropdown("PTSD denied")
      click_remove_intake_issue_dropdown("Left knee granted")
      click_remove_intake_issue_dropdown("Accrued")
      expect(page).to have_button("Save", disabled: false)
      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
      expect(appeal.tasks.filter(&:open?).any?).to eq false
      expect(appeal.tasks.where(type: VeteranRecordRequest.name).first.status).to eq(Constants.TASK_STATUSES.completed)
      expect(appeal.tasks.map(&:closed_at)).to match_array([Time.zone.now, Time.zone.now, Time.zone.now, Time.zone.now])
    end
  end

  context "ratings with disabiliity codes" do
    let(:disabiliity_receive_date) { receipt_date - 1.day }
    let(:disability_profile_date) { receipt_date - 10.days }
    let!(:ratings_with_diagnostic_codes) do
      generate_ratings_with_disabilities(
        veteran,
        disabiliity_receive_date,
        disability_profile_date
      )
    end

    scenario "saves diagnostic codes" do
      visit "appeals/#{appeal.uuid}/edit/"
      save_and_check_request_issues_with_diagnostic_codes(
        Constants.INTAKE_FORM_NAMES.appeal,
        appeal
      )
    end
  end

  context "with multiple request issues with same data fields" do
    let!(:duplicate_nonrating_request_issue) do
      create(:request_issue, nonrating_request_issue_attributes.merge(contention_reference_id: "4444"))
    end
    let!(:duplicate_rating_request_issue) do
      create(:request_issue, rating_request_issue_attributes.merge(contention_reference_id: "5555"))
    end

    scenario "saves by id" do
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content(duplicate_nonrating_request_issue.description, count: 2)
      expect(page).to have_content(duplicate_rating_request_issue.description, count: 2)

      # add another new issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        category: "Active Duty Adjustments",
        description: "A description!",
        date: profile_date.mdY
      )
      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      request_issue_update = RequestIssuesUpdate.where(review: appeal).last
      non_modified_ids = [duplicate_nonrating_request_issue.id, duplicate_rating_request_issue.id,
                          nonrating_request_issue.id, rating_request_issue.id]

      # duplicate issues should be neither added nor removed
      expect(request_issue_update.added_issues.map(&:id)).to_not include(non_modified_ids)
      expect(request_issue_update.removed_issues.map(&:id)).to_not include(non_modified_ids)
    end
  end

  context "with legacy appeals" do
    before do
      setup_legacy_opt_in_appeals(veteran.file_number)
    end

    context "with legacy_opt_in_approved" do
      let(:legacy_opt_in_approved) { true }

      scenario "adding issues" do
        visit "appeals/#{appeal.uuid}/edit/"

        click_intake_add_issue
        expect(page).to have_content("Next")
        add_intake_rating_issue("Left knee granted")

        # expect legacy opt in modal
        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")

        add_intake_rating_issue("intervertebral disc syndrome") # ineligible issue

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_appeal_not_eligible}"
        )

        click_intake_add_issue
        add_intake_rating_issue("Back pain")
        add_intake_rating_issue("ankylosis of hip") # eligible issue
        click_edit_submit_and_confirm

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        ineligible_ri = RequestIssue.find_by(
          contested_issue_description: "Left knee granted",
          ineligible_reason: :legacy_appeal_not_eligible,
          vacols_id: "vacols2",
          vacols_sequence_id: "1"
        )
        expect(ineligible_ri).to_not be_nil
        expect(ineligible_ri.closed_status).to eq("ineligible")

        ri_with_optin = RequestIssue.find_by(
          contested_issue_description: "Back pain",
          ineligible_reason: nil,
          vacols_id: "vacols1",
          vacols_sequence_id: "1"
        )

        expect(ri_with_optin).to_not be_nil
        li_optin = ri_with_optin.legacy_issue_optin
        expect(li_optin.optin_processed_at).to_not be_nil
        expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
          LegacyIssueOptin::VACOLS_DISPOSITION_CODE
        )

        # Check rollback
        visit "appeals/#{appeal.uuid}/edit/"
        click_remove_intake_issue_dropdown("Back pain")

        # Let's verify ineligible issue properly changes removed status
        click_remove_intake_issue_dropdown("Left knee granted")

        click_edit_submit_and_confirm

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
        expect(li_optin.reload.rollback_processed_at).to_not be_nil
        expect(VACOLS::CaseIssue.find_by(isskey: "vacols1", issseq: 1).issdc).to eq(
          li_optin.original_disposition_code
        )

        expect(ineligible_ri.reload.closed_status).to eq("removed")
      end
    end

    context "with legacy opt in not approved" do
      let(:legacy_opt_in_approved) { false }
      scenario "adding issues" do
        visit "appeals/#{appeal.uuid}/edit/"
        click_intake_add_issue
        add_intake_rating_issue("Left knee granted")

        expect(page).to have_content("Does issue 3 match any of these VACOLS issues?")
        # do not show inactive appeals when legacy opt in is false
        expect(page).to_not have_content("impairment of hip")
        expect(page).to_not have_content("typhoid arthritis")

        add_intake_rating_issue("ankylosis of hip")

        expect(page).to have_content(
          "Left knee granted #{Constants.INELIGIBLE_REQUEST_ISSUES.legacy_issue_not_withdrawn}"
        )

        safe_click("#button-submit-update")
        safe_click ".confirm"

        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        expect(RequestIssue.find_by(
                 contested_issue_description: "Left knee granted",
                 ineligible_reason: :legacy_issue_not_withdrawn,
                 vacols_id: "vacols1",
                 vacols_sequence_id: "1"
               )).to_not be_nil
      end
    end
  end

  context "User is a member of the Supervisory Senior Counsel" do
    before do
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:split_appeal_workflow)
      OrganizationsUser.make_user_admin(current_user, SupervisorySeniorCounsel.singleton)
    end

    after { FeatureToggle.disable!(:split_appeal_workflow) }

    scenario "less than 2 request issues on the appeal, the split appeal button doesn't show" do
      visit "appeals/#{appeal2.uuid}/edit/"
      expect(appeal2.decision_issues.length + appeal2.request_issues.length).to be < 2
      expect(page).to_not have_button("Split appeal")
    end

    context "and the appeal has 2 or more tasks" do
      let!(:request_issue_1) do
        create(:request_issue,
               id: 22,
               decision_review: appeal2,
               decision_date: profile_date,
               contested_rating_issue_reference_id: "def456",
               contested_rating_issue_profile_date: profile_date,
               contested_issue_description: "PTSD denied",
               contention_reference_id: "3897",
               benefit_type: "Education")
      end

      let!(:request_issue_2) do
        create(:request_issue,
               id: 25,
               decision_review: appeal2,
               decision_date: profile_date,
               contested_rating_issue_reference_id: "blah1234",
               contested_rating_issue_profile_date: profile_date,
               contested_issue_description: "Other Issue Description",
               contention_reference_id: "78910",
               benefit_type: "Education")
      end

      scenario "Split appeal page behavior" do
        step "SSC user navigates to the split appeal page" do
          visit "appeals/#{appeal2.uuid}/edit/"

          expect(page).to have_button("Split appeal")
          # clicking the button takes the user to the next page
          click_button("Split appeal")

          expect(page).to have_current_path("/appeals/#{appeal2.uuid}/edit/create_split")
        end

        step "The split appeal page contains the appropriate information" do
          expect(page).to have_content("PTSD denied")
          expect(page).to have_content("Other Issue Description")

          # expect the select bar, cancel button, and continue button to show
          expect(page).to have_content("Select...")
          expect(page).to have_content("Cancel")

          # expect the continue button to be disabled
          expect(page).to have_button("Continue", disabled: true)

          # The cancel button goes back to the edit page
          click_button("Cancel")
          expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}")
        end

        step "If no issues and no reason are selected on the split appeal page, the Continue button is disabled" do
          visit("/appeals/#{appeal2.uuid}/edit/create_split")

          # expect issue descriptions to display
          expect(page).to have_content("PTSD denied")
          expect(page).to have_content("Other Issue Description")
          expect(page).to have_content("Select...")
          expect(page).to have_button("Continue", disabled: true)
        end

        step "If a reason is selected the button remains disabled" do
          find(:css, ".cf-select").select_option
          find(:css, ".cf-select__menu").click
          expect(page).to have_button("Continue", disabled: true)
        end

        step "If an issue is selected and then de-selected the Continue button behaves correctly" do
          find("label", text: "PTSD denied").click
          expect(page).to have_button("Continue", disabled: false)
          find("label", text: "PTSD denied").click
          expect(page).to have_button("Continue", disabled: true)
        end

        step "If all issues are selected on the split appeal page, the Continue button is disabled" do
          find("label", text: "PTSD denied").click
          find("label", text: "Other Issue Description").click

          expect(page).to have_button("Continue", disabled: true)
        end

        step "The SSC user navigates to the split appeal page to review page" do
          find("label", text: "PTSD denied").click
          click_button("Continue")
          expect(page).to have_content("Reason for new appeal stream:")
          expect(page).to have_current_path("/appeals/#{appeal2.uuid}/edit/review_split")
        end
      end

      def skill_form(appeal)
        visit("/appeals/#{appeal.uuid}/edit/create_split")

        # expect issue descritions to display
        expect(page).to have_content("PTSD denied")
        expect(page).to have_content("Other Issue Description")
        find("label", text: "PTSD denied").click
        expect(page).to have_content("Select...")

        find(:css, ".cf-select").select_option
        find(:css, ".cf-select__menu").click

        click_button("Continue")
        expect(page).to have_current_path("/appeals/#{appeal.uuid}/edit/review_split")
      end

      def specialty_case_team_split_form(appeal)
        visit("/appeals/#{appeal.uuid}/edit/create_split")

        # expect issue descritions to display
        expect(page).to have_content("PTSD denied")
        expect(page).to have_content("Other Issue Description")
        expect(page).to have_content("CHAMPVA Split Issue")
        find("label", text: "CHAMPVA Split Issue").click
        expect(page).to have_content("Select...")

        find(:css, ".cf-select").select_option
        find(:css, ".cf-select__menu").click

        click_button("Continue")
        expect(page).to have_current_path("/appeals/#{appeal.uuid}/edit/review_split")
      end

      # scenario "When the user accesses the review_split page, the page renders as expected" do
      scenario "Review split page behavior" do
        step "When the user accesses the review_split page, the page renders as expected" do
          skill_form(appeal2)

          expect(page).to have_table("review_table")
          expect(page).to have_content("Cancel")
          expect(page).to have_button("Back")
          expect(page).to have_button("Split appeal")
          expect(page).to have_content("Reason for new appeal stream:")
          expect(appeal2.docket_type).not_to have_content("hearing")

          # Verify table information
          row2_1 = page.find(:xpath, ".//table/tr[2]/td[1]/em").text
          row3_1 = page.find(:xpath, ".//table/tr[3]/td[1]/em").text
          expect(row2_1).to eq("Veteran")
          if expect(appeal2.veteran_is_not_claimant).to be(false)
            expect(row3_1).to eq("Docket Number")
          else
            expect(row3_1).to eq("Appellant")
          end
        end

        step "the back button takes the user back" do
          click_button("Back")
          expect(page).to have_content("Create new appeal stream")
          expect(page).to have_current_path("/appeals/#{appeal2.uuid}/edit/create_split")
        end

        step "the cancel button takes the user back to the appeal case details page" do
          skill_form(appeal2)
          expect(page).to have_button("Split appeal")
          click_button("Cancel")
          expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}")
        end

        step "the Split appeal button splits appeal and takes the user back to the original appeal case details page" do
          skill_form(appeal2)

          click_button("Split appeal")
          expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}", ignore_query: true)

          # Verify the success banner
          expect(page).to have_content("You have successfully split #{appeal2.claimant.name}'s appeal")
          expect(page).to have_content(COPY::SPLIT_APPEAL_BANNER_SUCCESS_MESSAGE)

          # Verify the spit appeal information
          appeal2.reload
          split_record = SplitCorrelationTable.last
          new_appeal = Appeal.find(split_record.appeal_id)
          expect(split_record.original_appeal_id).to eq(appeal2.id)
          expect(new_appeal.request_issues.first.contested_issue_description).to eq("PTSD denied")
          expect(appeal2.request_issues.active.count).to eq(1)
          expect(new_appeal.docket_number).to eq(appeal2.docket_number)
        end
      end

      context "When splitting appeals with Specialty Case Team issues" do
        let!(:request_issue_3) do
          create(:request_issue,
                 id: 28,
                 decision_review: appeal2,
                 decision_date: profile_date,
                 benefit_type: "vha",
                 nonrating_issue_category: "CHAMPVA",
                 nonrating_issue_description: "CHAMPVA Split Issue")
        end

        context "With feature toggle enabled" do
          before { FeatureToggle.enable!(:specialty_case_team_distribution) }
          after { FeatureToggle.disable!(:specialty_case_team_distribution) }

          scenario "Split appeal with Vha issue" do
            step "The split appeal should progress through to the review split page" do
              specialty_case_team_split_form(appeal2)
            end

            step "the banner should be on the page indicating that it is a specialty case team issue" do
              expect(page).to have_content(COPY::SPLIT_APPEAL_SPECIALTY_CASE_TEAM_ISSUE_MESSAGE)
            end

            step "The appeal should be split succesfully and user should be redirected back to the case details page" do
              evidence_submission_task = appeal2.tasks.find { |task| task.type == EvidenceSubmissionWindowTask.name }
              distribution_task = appeal2.tasks.find { |task| task.type == DistributionTask.name }
              # complete the distribution task so that a SpecialtyCaseTeamAssignTask can be created
              evidence_submission_task.completed!
              distribution_task.completed!
              click_button("Split appeal")
              expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}", ignore_query: true)

              # Verify the success banner
              expect(page).to have_content("You have successfully split #{appeal2.claimant.name}'s appeal")
              expect(page).to have_content(COPY::SPLIT_APPEAL_BANNER_SUCCESS_MESSAGE)

              # Verify the spit appeal information
              appeal2.reload
              split_record = SplitCorrelationTable.last
              new_appeal = Appeal.find(split_record.appeal_id)
              expect(split_record.original_appeal_id).to eq(appeal2.id)
              expect(new_appeal.request_issues.first.nonrating_issue_category).to eq("CHAMPVA")
              expect(appeal2.request_issues.active.count).to eq(2)
              expect(new_appeal.request_issues.active.count).to eq(1)
              expect(new_appeal.docket_number).to eq(appeal2.docket_number)

              # The new appeal should have an assigned SCT task
              sct_task = new_appeal.tasks.find { |task| task.type == SpecialtyCaseTeamAssignTask.name }
              expect(sct_task.status).to eq(Constants.TASK_STATUSES.assigned)
            end
          end
        end

        context "With sct feature toggle disabled" do
          scenario "Split appeal with Vha issue" do
            step "The split appeal should progress through to the review split page" do
              specialty_case_team_split_form(appeal2)
            end

            step "the sct banner should not be on the page indicating that it is a specialty case team issue" do
              expect(page).to_not have_content(COPY::SPLIT_APPEAL_SPECIALTY_CASE_TEAM_ISSUE_MESSAGE)
            end

            step "The appeal should be split succesfully and user should be redirected back to the case details page" do
              click_button("Split appeal")
              expect(page).to have_current_path("/queue/appeals/#{appeal2.uuid}", ignore_query: true)

              page.find("a", text: "refresh the page").click if page.has_text?("Unable to load this case")

              # Verify the success banner
              expect(page).to have_content("You have successfully split #{appeal2.claimant.name}'s appeal")
              expect(page).to have_content(COPY::SPLIT_APPEAL_BANNER_SUCCESS_MESSAGE)

              # Verify the spit appeal information
              appeal2.reload
              split_record = SplitCorrelationTable.last
              new_appeal = Appeal.find(split_record.appeal_id)
              expect(split_record.original_appeal_id).to eq(appeal2.id)
              expect(new_appeal.request_issues.first.nonrating_issue_category).to eq("CHAMPVA")
              expect(appeal2.request_issues.active.count).to eq(2)
              expect(new_appeal.request_issues.active.count).to eq(1)
              expect(new_appeal.docket_number).to eq(appeal2.docket_number)

              # The new appeal should not have an assigned SCT task
              sct_task = new_appeal.tasks.find { |task| task.type == SpecialtyCaseTeamAssignTask.name }
              expect(sct_task).to eq(nil)
            end
          end
        end
      end
    end
  end

  context "Veteran is invalid" do
    let!(:veteran) do
      create(:veteran,
             first_name: "Ed",
             last_name: "Merica",
             ssn: nil,
             bgs_veteran_record: {
               sex: nil,
               ssn: nil,
               country: nil,
               address_line1: "this address is more than 20 chars"
             })
    end

    let!(:rating_request_issue) { nil }
    let!(:nonrating_request_issue) { nil }

    scenario "adding an issue with a vbms benefit type" do
      visit "appeals/#{appeal.uuid}/edit/"

      # Add issue that is not a VBMS issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        benefit_type: "Education",
        category: "Accrued",
        description: "Description for Accrued",
        date: 1.day.ago.to_date.mdY
      )
      expect(page).to_not have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: false)

      # Add a rating issue
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      expect(page).to have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_content("Please fill in the following fields in the Veteran's profile in VBMS or")
      expect(page).to have_content(
        "the corporate database, then retry establishing the EP in Caseflow: country"
      )
      expect(page).to have_content("This Veteran's address is too long. Please edit it in VBMS or SHARE")
      expect(page).to have_button("Save", disabled: true)
      click_remove_intake_issue_dropdown("Left knee granted")
      expect(page).to_not have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: false)

      # Add a compensation nonrating issue
      click_intake_add_issue
      click_intake_no_matching_issues
      add_intake_nonrating_issue(
        benefit_type: "Compensation",
        category: "Apportionment",
        description: "Description for Apportionment",
        date: 2.days.ago.to_date.mdY
      )
      expect(page).to have_content("Check the Veteran's profile for invalid information")
      expect(page).to have_button("Save", disabled: true)
    end
  end

  context "when appeal Type is Veterans Health Administration" do
    scenario "appeal with benefit type VHA (predocket)" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_intake_add_issue
      click_intake_no_matching_issues
      fill_in "Benefit type", with: "Veterans Health Administration"
      find("#issue-benefit-type").send_keys :enter
      fill_in "Issue category", with: "Beneficiary Travel"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "I am a VHA issue"
      fill_in "Decision date", with: 1.month.ago.mdY
      radio_choices = page.all(".cf-form-radio-option > label")
      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")
      expect(find("#is-predocket-needed_true", visible: false).checked?).to eq(true)
      expect(find("#is-predocket-needed_false", visible: false).checked?).to eq(false)
      expect(page).to have_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
    end

    scenario "appeal with benefit type VHA no - predocket" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_intake_add_issue
      click_intake_no_matching_issues
      fill_in "Benefit type", with: "Veterans Health Administration"
      find("#issue-benefit-type").send_keys :enter
      fill_in "Issue category", with: "Beneficiary Travel"
      find("#issue-category").send_keys :enter
      fill_in "Issue description", with: "I am a VHA issue"
      fill_in "Decision date", with: 1.month.ago.mdY
      radio_choices = page.all(".cf-form-radio-option > label")
      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")

      radio_choices[1].click
      expect(find("#is-predocket-needed_true", visible: false).checked?).to eq(false)
      expect(find("#is-predocket-needed_false", visible: false).checked?).to eq(true)
      expect(page).to have_no_content(COPY::VHA_PRE_DOCKET_ISSUE_BANNER)
    end
  end

  context "appeal is outcoded" do
    let(:appeal) { create(:appeal, :outcoded, veteran: veteran) }

    scenario "error message is shown and no edit is allowed" do
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_current_path("/appeals/#{appeal.uuid}/edit/outcoded")
      expect(page).to have_content("Issues Not Editable")
      expect(page).to have_content("This appeal has been outcoded and the issues are no longer editable.")
    end
  end

  context "when withdraw decision reviews is enabled" do
    let(:withdraw_date) { 1.day.ago.to_date.mdY }

    let!(:in_progress_task) do
      create(:appeal_task,
             :in_progress,
             appeal: appeal,
             assigned_to: non_comp_org,
             assigned_at: last_week)
    end

    scenario "user can withdraw single issue and edit page shows previously withdrawn issues" do
      step "withdraw an issue" do
        visit "appeals/#{appeal.uuid}/edit/"

        expect(page).to_not have_content("Withdrawn issues")
        expect(page).to_not have_content("Please include the date the withdrawal was requested")

        click_withdraw_intake_issue_dropdown("PTSD denied")

        expect(page).to have_content(
          /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
        )
        expect(page).to have_content("Please include the date the withdrawal was requested")

        expect(page).to have_button("Save", disabled: true)

        fill_in "withdraw-date", with: withdraw_date

        safe_click("#button-submit-update")
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first

        expect(withdrawn_issue).to_not be_nil
        expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)
        expect(page).to have_content("You have successfully withdrawn 1 issue.")
      end

      step "show withdrawn issue when appeal edit page is reloaded" do
        # reload to verify that the new issues populate the form
        visit "appeals/#{appeal.uuid}/edit/"

        expect(page).to have_content(
          /Withdrawn issues\s*[0-9]+\. PTSD denied\s*Decision date: #{request_issue_decision_mdY}\s*Withdrawn on/i
        )
      end

      step "show alert when withdrawal date is not valid" do
        click_withdraw_intake_issue_dropdown("Military Retired Pay - nonrating description")
        fill_in "withdraw-date", with: 50.days.ago.to_date.mdY

        expect(page).to have_content(
          "We cannot process your request. Please select a date after the Appeal's receipt date."
        )
        expect(page).to have_button("Withdraw", disabled: true)

        fill_in "withdraw-date", with: 2.years.from_now.to_date.mdY

        expect(page).to have_content("We cannot process your request. Please select a date prior to today's date.")
        expect(page).to have_button("Withdraw", disabled: true)
      end
    end

    scenario "withdraw entire review and show alert" do
      visit "appeals/#{appeal.uuid}/edit/"

      click_withdraw_intake_issue_dropdown("PTSD denied")
      fill_in "withdraw-date", with: withdraw_date

      expect(page).to_not have_content("This review will be withdrawn.")
      expect(page).to have_button("Save", disabled: false)

      click_withdraw_intake_issue_dropdown("Military Retired Pay - nonrating description")
      fill_in "withdraw-date", with: 2.days.ago.to_date.mdY

      expect(page).to have_content("This review will be withdrawn.")
      expect(page).to have_button("Withdraw", disabled: false)

      click_edit_submit

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully withdrawn a review.")

      expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
    end

    scenario "show alert when issue is added, removed and withdrawn" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")
      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully added 1 issue")

      # reload to verify that the new issues populate the form
      visit "appeals/#{appeal.uuid}/edit/"

      click_intake_add_issue
      add_intake_rating_issue("Back pain")

      click_remove_intake_issue_dropdown("Military Retired Pay")

      click_withdraw_intake_issue_dropdown("PTSD denied")

      expect(page).to have_content(
        /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
      )
      expect(page).to have_content("Please include the date the withdrawal was requested")

      expect(page).to have_button("Save", disabled: true)

      fill_in "withdraw-date", with: withdraw_date

      click_edit_submit

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully added 1 issue, removed 1 issue, and withdrawn 1 issue.")
    end
  end

  context "with BVA Intake Admin user" do
    # creates organization
    let(:bva_intake) { BvaIntake.singleton }
    # creates admin user
    let(:bva_intake_admin_user) { create(:user, roles: ["Mail Intake"]) }

    let(:legacy_appeal_mst_pact_unchecked) do
      create(
        :legacy_appeal,
        :with_veteran,
        vacols_case: create(
          :case,
          case_issues: [
            create(:case_issue, issmst: "N", isspact: "N")
          ]
        )
      )
    end

    before do
      # joins the user with the organization to grant access to role and org permissions
      OrganizationsUser.make_user_admin(bva_intake_admin_user, bva_intake)
      # authenticates and sets the user
      User.authenticate!(user: bva_intake_admin_user)
    end

    def go_to_queue_edit_issues_page_with_legacy_appeal(legacy_appeal)
      visit "/queue"
      click_on "Search cases"
      fill_in "search", with: legacy_appeal.veteran_file_number
      click_on "Search"
      click_on legacy_appeal.docket_number
      click_on "Correct issues"
    end

    context "with Legacy MST/PACT identifications" do
      before do
        FeatureToggle.enable!(:mst_identification)
        FeatureToggle.enable!(:pact_identification)
        FeatureToggle.enable!(:legacy_mst_pact_identification)
      end

      after do
        FeatureToggle.disable!(:mst_identification)
        FeatureToggle.disable!(:pact_identification)
        FeatureToggle.disable!(:legacy_mst_pact_identification)
      end

      it "issues can be modified" do
        step "can add MST/PACT to issues" do
          go_to_queue_edit_issues_page_with_legacy_appeal(legacy_appeal_mst_pact_unchecked)
          click_edit_intake_issue_dropdown_by_number(1)
          check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
          find(:xpath, "//label[@for='PACT Act']").click(allow_label_click: true, visible: false)
          click_on "Save"

          click_on "Save"

          expect(page).to have_content("MST and PACT")
        end

        step "can remove MST/PACT issues" do
          click_on "Correct issues"
          click_edit_intake_issue_dropdown_by_number(1)
          uncheck("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
          find(:xpath, "//label[@for='PACT Act']").click(allow_label_click: true, visible: false)
          click_on "Save"

          click_on "Save"

          expect(page).to have_no_content("MST and PACT")
        end

        step "can add and remove only PACT to an issue" do
          click_on "Correct issues"
          click_edit_intake_issue_dropdown_by_number(1)
          find(:xpath, "//label[@for='PACT Act']").click(allow_label_click: true, visible: false)
          click_on "Save"

          click_on "Save"
          expect(page).to have_content("SPECIAL ISSUES\nPACT")

          click_on "Correct issues"
          click_edit_intake_issue_dropdown_by_number(1)
          find(:xpath, "//label[@for='PACT Act']").click(allow_label_click: true, visible: false)
          click_on "Save"

          click_on "Save"
          expect(page).to have_no_content("SPECIAL ISSUES\nPact")
        end

        step "can add and remove only MST to an issue" do
          click_on "Correct issues"
          click_edit_intake_issue_dropdown_by_number(1)
          check("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
          click_on "Save"

          click_on "Save"
          expect(page).to have_content("SPECIAL ISSUES\nMST")

          click_on "Correct issues"
          click_edit_intake_issue_dropdown_by_number(1)
          uncheck("Military Sexual Trauma (MST)", allow_label_click: true, visible: false)
          click_on "Save"

          click_on "Save"
          expect(page).to have_no_content("SPECIAL ISSUES\nMST")
        end
      end
    end
  end

  context "when benefit type is initially non-vha" do
    let!(:appeal3) do
      create(:appeal,
             :assigned_to_judge,
             :completed_distribution_task,
             veteran_file_number: create(:veteran).file_number,
             receipt_date: receipt_date,
             docket_type: Constants.AMA_DOCKETS.direct_review)
    end
    let!(:request_issue) do
      create(:request_issue,
             benefit_type: "compensation",
             nonrating_issue_category: "Unknown Issue Category",
             nonrating_issue_description: "non vha issue",
             decision_date: 5.months.ago,
             decision_review: appeal3)
    end
    let(:sct_user) { create(:user) }
    before do
      SpecialtyCaseTeam.singleton.add_user(sct_user)
      BvaIntake.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:specialty_case_team_distribution)
    end
    after { FeatureToggle.disable!(:specialty_case_team_distribution) }

    scenario "appeal moves to sct queue when vha issue is added and moves back to distribution when removed" do
      step "add VHA issue and remove non-VHA issue" do
        reload_case_detail_page(appeal3.uuid)
        click_on "Correct issues"
        click_remove_intake_issue_dropdown("Unknown Issue Category")
        click_intake_add_issue
        fill_in "Benefit type", with: "Veterans Health Administration"
        find("#issue-benefit-type").send_keys :enter
        fill_in "Issue category", with: "Beneficiary Travel"
        find("#issue-category").send_keys :enter
        fill_in "Issue description", with: "I am a VHA issue"
        fill_in "Decision date", with: 5.months.ago.mdY
        radio_choices = page.all(".cf-form-radio-option > label")
        radio_choices[1].click
        safe_click ".add-issue"

        click_edit_submit
        expect(page).to have_content("Move appeal to SCT queue")
        expect(page).to have_button("Move")
        safe_click ".confirm"
        expect(page).to have_content("You have successfully updated issues on this appeal")
        expect(page).to have_content(
          "The appeal for #{appeal3.claimant.name} " \
          "(ID: #{appeal3.veteran.file_number}) has been moved to the SCT queue."
        )
      end

      step "remove VHA issue and add non-VHA issue" do
        reload_case_detail_page(appeal3.uuid)
        click_on "Correct issues"
        click_remove_intake_issue_dropdown("Beneficiary Travel")
        click_intake_add_issue
        add_intake_nonrating_issue(
          benefit_type: "compensation",
          category: "Unknown Issue Category",
          description: "non vha issue",
          date: 1.day.ago.to_date.mdY
        )

        click_edit_submit
        expect(page).to have_content(COPY::MOVE_TO_DISTRIBUTION_MODAL_TITLE)
        expect(page).to have_content(COPY::MOVE_TO_DISTRIBUTION_MODAL_BODY)
        expect(page).to have_button("Move")
        safe_click ".confirm"
        expect(page).to have_content("You have successfully updated issues on this appeal")
        expect(page).to have_content(
          "The appeal for #{appeal3.claimant.name} " \
          "(ID: #{appeal3.veteran.file_number}) has been moved to the regular distribution pool."
        )
        expect(page).to have_current_path("/queue/appeals/#{appeal3.uuid}")

        # Verify task tree status
        appeal3.reload
        appeal3.tasks.reload
        appeal3.request_issues.reload
        distribution_task = appeal3.tasks.find { |task| task.is_a?(DistributionTask) }
        expect(distribution_task.assigned_by).to eq(current_user)
        expect(distribution_task.status).to eq("assigned")
        expect(appeal3.ready_for_distribution?).to eq(true)
        expect(appeal3.can_redistribute_appeal?).to eq(true)
        expect(appeal3.request_issues.active.count).to eq(1)
        expect(appeal3.tasks.find { |task| task.is_a?(SpecialtyCaseTeamAssignTask) }.status).to eq("cancelled")
      end
    end
  end
end
