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

  let!(:current_user) do
    User.authenticate!(roles: ["Mail Intake"])
  end

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

  scenario "allows adding/removing issues" do
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

    # going back to edit page should show those issues
    visit "appeals/#{appeal.uuid}/edit/"
    expect(page).to have_content("Left knee granted")
    expect(page.has_no_content?("nonrating description")).to eq(true)

    # canceling should redirect to queue
    click_on "Cancel"
    expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
  end

  scenario "allows removing and re-adding same issue" do
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

  context "with remove decision review enabled" do
    scenario "allows all request issues to be removed and saved" do
      visit "appeals/#{appeal.uuid}/edit/"
      # remove all issues
      click_remove_intake_issue_dropdown("PTSD denied")
      click_remove_intake_issue_dropdown("Military Retired Pay")
      expect(page).to have_button("Save", disabled: false)
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

  context "appeal is non-comp benefit type" do
    let!(:request_issue) { create(:request_issue, benefit_type: "education") }

    scenario "adding an issue with a non-comp benefit type" do
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
      expect(page).to_not have_content("Unable to load this case")
      expect(RequestIssue.find_by(
               benefit_type: "education",
               veteran_participant_id: nil
             )).to_not be_nil
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
    scenario "remove an issue with dropdown and show alert message" do
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("PTSD denied")
      click_remove_intake_issue_dropdown("PTSD denied")

      expect(page).to_not have_content("PTSD denied")

      click_edit_submit_and_confirm

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully removed 1 issue.")
    end

    let(:withdraw_date) { 1.day.ago.to_date.mdY }

    let!(:in_progress_task) do
      create(:appeal_task,
             :in_progress,
             appeal: appeal,
             assigned_to: non_comp_org,
             assigned_at: last_week)
    end

    scenario "withdraw entire review and show alert" do
      visit "appeals/#{appeal.uuid}/edit/"

      click_withdraw_intake_issue_dropdown("PTSD denied")
      fill_in "withdraw-date", with: withdraw_date

      expect(page).to_not have_content("This review will be withdrawn.")
      expect(page).to have_button("Save", disabled: false)

      click_withdraw_intake_issue_dropdown("Military Retired Pay - nonrating description")

      expect(page).to have_content("This review will be withdrawn.")
      expect(page).to have_button("Withdraw", disabled: false)

      click_edit_submit

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      expect(page).to have_content("You have successfully withdrawn a review.")

      expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
    end

    scenario "withdraw an issue" do
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

    scenario "show withdrawn issue when appeal edit page is reloaded" do
      visit "appeals/#{appeal.uuid}/edit/"

      click_intake_add_issue
      add_intake_rating_issue("Left knee granted")

      expect(page).to have_button("Save", disabled: false)

      safe_click("#button-submit-update")
      expect(page).to have_content("Number of issues has changed")

      safe_click ".confirm"
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      # reload to verify that the new issues populate the form
      visit "appeals/#{appeal.uuid}/edit/"
      expect(page).to have_content("Left knee granted")

      click_withdraw_intake_issue_dropdown("PTSD denied")

      expect(page).to_not have_content(/Requested issues\s*[0-9]+\. PTSD denied/i)
      expect(page).to have_content(
        /Withdrawn issues\n[1-2]..PTSD denied\nDecision date: #{request_issue_decision_mdY}\nWithdrawal pending/i
      )
      expect(page).to have_content("Please include the date the withdrawal was requested")

      fill_in "withdraw-date", with: withdraw_date

      safe_click("#button-submit-update")
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

      withdrawn_issue = RequestIssue.where(closed_status: "withdrawn").first
      expect(withdrawn_issue).to_not be_nil
      expect(withdrawn_issue.closed_at).to eq(1.day.ago.to_date.to_datetime)

      sleep 1

      # reload to verify that the new issues populate the form
      visit "appeals/#{appeal.uuid}/edit/"

      expect(page).to have_content(
        /Withdrawn issues\s*[0-9]+\. PTSD denied\s*Decision date: #{request_issue_decision_mdY}\s*Withdrawn on/i
      )
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

    scenario "show alert when withdrawal date is not valid" do
      visit "appeals/#{appeal.uuid}/edit/"
      click_withdraw_intake_issue_dropdown("PTSD denied")
      fill_in "withdraw-date", with: 50.days.ago.to_date.mdY

      expect(page).to have_content(
        "We cannot process your request. Please select a date after the Appeal's receipt date."
      )
      expect(page).to have_button("Save", disabled: true)

      fill_in "withdraw-date", with: 2.years.from_now.to_date.mdY

      expect(page).to have_content("We cannot process your request. Please select a date prior to today's date.")
      expect(page).to have_button("Save", disabled: true)
    end
  end

  context "when remove decision reviews is enabled" do
    let(:today) { Time.zone.now }
    let(:appeal) do
      # reload to get uuid
      create(:appeal, veteran_file_number: veteran.file_number).reload
    end
    let!(:existing_request_issues) do
      [create(:request_issue, :nonrating, decision_review: appeal),
       create(:request_issue, :nonrating, decision_review: appeal)]
    end

    let!(:completed_task) do
      create(:appeal_task,
             :completed,
             appeal: appeal,
             assigned_to: non_comp_org,
             closed_at: last_week)
    end

    let!(:cancelled_task) do
      create(:appeal_task,
             :cancelled,
             appeal: appeal,
             assigned_to: non_comp_org,
             closed_at: Time.zone.now)
    end

    context "when review has multiple active tasks" do
      let!(:in_progress_task) do
        create(:appeal_task,
               :in_progress,
               appeal: appeal,
               assigned_to: non_comp_org,
               assigned_at: last_week)
      end

      scenario "cancel all active tasks when all request issues are removed" do
        visit "appeals/#{appeal.uuid}/edit"
        # remove all request issues
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("Apportionment")
        click_remove_intake_issue_dropdown("PTSD denied")
        click_remove_intake_issue_dropdown("Military Retired Pay")

        click_edit_submit_and_confirm
        expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

        expect(RequestIssue.find_by(
                 benefit_type: "compensation",
                 veteran_participant_id: nil
               )).to_not be_nil

        visit "appeals/#{appeal.uuid}/edit"
        expect(page.has_no_content?(existing_request_issues.first.description)).to eq(true)
        expect(page.has_no_content?(existing_request_issues.second.description)).to eq(true)
        expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        expect(in_progress_task.reload.status).to eq(Constants.TASK_STATUSES.cancelled)
      end

      context "when appeal is non-comp benefit type" do
        let!(:request_issue) { create(:request_issue, benefit_type: "education") }

        scenario "remove all non-comp decision reviews" do
          visit "appeals/#{appeal.uuid}/edit"

          # remove all request issues
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("PTSD denied")
          click_remove_intake_issue_dropdown("Military Retired Pay")
          click_edit_submit_and_confirm

          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")
          expect(page).to have_content("Edit Completed")
        end
      end

      context "when review has no active tasks" do
        scenario "no tasks are cancelled when all request issues are removed" do
          visit "appeals/#{appeal.uuid}/edit"

          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("PTSD denied")
          click_remove_intake_issue_dropdown("Military Retired Pay")
          click_edit_submit_and_confirm
          expect(completed_task.reload.status).to eq(Constants.TASK_STATUSES.completed)
        end
      end

      context "when appeal task is cancelled" do
        scenario "show timestamp when all request issues are cancelled" do
          visit "appeals/#{appeal.uuid}/edit"
          # remove all request issues

          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("Apportionment")
          click_remove_intake_issue_dropdown("PTSD denied")
          click_remove_intake_issue_dropdown("Military Retired Pay")

          click_edit_submit_and_confirm
          expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}")

          visit "appeals/#{appeal.uuid}/edit"
          expect(page.has_no_content?(existing_request_issues.first.description)).to eq(true)
          expect(page.has_no_content?(existing_request_issues.second.description)).to eq(true)
          expect(cancelled_task.status).to eq(Constants.TASK_STATUSES.cancelled)
          expect(cancelled_task.closed_at).to eq(Time.zone.now)
        end
      end
    end
  end
end
