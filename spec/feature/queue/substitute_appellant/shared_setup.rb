# frozen_string_literal: true

RSpec.shared_context("with Clerk of the Board user") do
  let(:cotb_org) { ClerkOfTheBoard.singleton }

  before do
    cotb_org.add_user(user)
    User.authenticate!(user: user)
  end
end

RSpec.shared_context("with recognized_granted_substitution_after_dd feature toggle") do
  before { FeatureToggle.enable!(:recognized_granted_substitution_after_dd) }
  after { FeatureToggle.disable!(:recognized_granted_substitution_after_dd) }
end

RSpec.shared_context("with hearings_substitution_death_dismissal feature toggle") do
  before { FeatureToggle.enable!(:hearings_substitution_death_dismissal) }
  after { FeatureToggle.disable!(:hearings_substitution_death_dismissal) }
end

RSpec.shared_context "with existing relationships" do
  let(:veteran_file_number) { appeal.veteran.file_number }
  let(:relationships) do
    [
      build(:relationship, :spouse, veteran_file_number: veteran_file_number).serialize,
      build(:relationship, :child, veteran_file_number: veteran_file_number).serialize,
      build(:relationship, :other, veteran_file_number: veteran_file_number).serialize
    ].map do |item|
      item[:ptcpnt_id] = item.delete :participant_id
      item
    end
  end

  before do
    allow_any_instance_of(Fakes::BGSService).to receive(:find_all_relationships).and_return(relationships)
    if docket_type.eql?("evidence_submission")
      EvidenceSubmissionWindowTask.find_or_create_by(appeal: appeal).update!(status: "completed")
    end
  end
end

RSpec.shared_examples("substitution unavailable") do
  it "does not show button to start substitution" do
    visit "/queue/appeals/#{appeal.uuid}"

    expect(page).to_not have_content "+ Add Substitute"
  end
end

RSpec.shared_examples("fill substitution form") do
  it "allows user to designate a substitute appellant" do
    step "user sets basic info for substitution" do
      visit "/queue/appeals/#{appeal.uuid}"

      # Navigate to substitution page
      page.find("button", text: "+ Add Substitute").click

      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/basics")
      expect(page).to have_content "Select substitute appellant"
      expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")

      # Fill form
      fill_in "When was substitution granted for this appellant?", with: substitution_date

      # Select second relationship
      find("label[for=participantId_#{relationships[1][:ptcpnt_id]}").click

      page.find("button", text: "Continue").click
    end

    # POA step will be relevant for future work
    # step "select POA form" do
    #   expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/poa")

    #   expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_SELECT_POA_TITLE
    #   expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")
    #   expect(page).to have_css(".cf-progress-bar-activated", text: "Select POA")

    #   page.find("button", text: "Continue").click
    # end

    step "create tasks form" do
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/tasks")

      # progress bar section"
      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_CREATE_TASKS_TITLE
      expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")
      # expect(page).to have_css(".cf-progress-bar-activated", text: "Select POA")
      expect(page).to have_css(".cf-progress-bar-activated", text: "Create task")
      expect(page).to have_css(".cf-progress-bar-not-activated", text: "Review")

      # key details section
      expect(page).to have_content(COPY::SUBSTITUTE_APPELLANT_KEY_DETAILS_TITLE)
      expect(page).to have_content("Notice of disagreement received")
      expect(page).to have_content("Veteran date of death")
      expect(page).to have_content("Substitution granted by the RO")

      # tasks selection
      distribution_task = DistributionTask.find_by(appeal_id: appeal.id)
      expect(distribution_task.closed_at).to_not be_nil

      if docket_type.eql?("evidence_submission")
        evidence_submission_task = EvidenceSubmissionWindowTask.find_by(appeal_id: appeal.id)
        evidence_task_id = evidence_submission_task.id
        expect(evidence_submission_task.closed_at).to_not be_nil
      end

      expect(page).to have_content(COPY::SUBSTITUTE_APPELLANT_TASK_SELECTION_TITLE)
      expect(page).to have_text("Listed below are all the tasks from the original appeal")
      expect(page).to have_css(".usa-table-borderless.css-nil")
      expect(page).to have_css(".usa-table-borderless.css-nil thead tr th", text: "Select")
      expect(page).to have_css(".usa-table-borderless.css-nil thead tr th", text: "Task")
      expect(page).to have_css(".usa-table-borderless.css-nil thead tr th", text: "Status")
      expect(page).to have_css(".usa-table-borderless.css-nil thead tr th", text: "Date")

      # there should always be a distrubution task
      expect(page).to have_css(".usa-table-borderless.css-nil tbody tr td", text: "Distribution")

      # example appeal has an evidence submission task
      if docket_type.eql?("evidence_submission")
        expect(page).to have_css(".usa-table-borderless.css-nil tbody tr td", text: "Evidence Submission Window")
        find("div", class: "checkbox-wrapper-taskIds[#{evidence_task_id}]").find("label").click
      end

      if docket_type.eql?("hearing")
        schedule_hearing_task = ScheduleHearingTask.find_by(appeal_id: appeal.id)
        schedule_hearing_task_id = schedule_hearing_task.id
        expect(page).to have_css(".usa-table-borderless.css-nil tbody tr td", text: "Schedule hearing")

        find("div", class: "checkbox-wrapper-taskIds[#{schedule_hearing_task_id}]").find("label").click
        expect(page).to have_content(COPY::SUBSTITUTE_APPELLANT_SCHEDULE_HEARING_TASK_ALERT_TEXT)

        find("div", class: "checkbox-wrapper-taskIds[#{schedule_hearing_task_id}]").find("label").click
        expect(page).to_not have_content(COPY::SUBSTITUTE_APPELLANT_SCHEDULE_HEARING_TASK_ALERT_TEXT)
      end
      page.find("button", text: "Continue").click
    end

    step "review/confirm page" do
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/substitute_appellant/review")

      expect(page).to have_css(".cf-progress-bar-activated", text: "Select substitute appellant")
      # expect(page).to have_css(".cf-progress-bar-activated", text: "Select POA")
      expect(page).to have_css(".cf-progress-bar-activated", text: "Create task")
      expect(page).to have_css(".cf-progress-bar-activated", text: "Review")

      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_REVIEW_TITLE
      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD
      expect(page).to have_content("Substitution granted by the RO")
      expect(page).to have_content("Name")
      expect(page).to have_content("Relation to Veteran")

      expect(page).to have_content("Reactivated tasks")
      page.find("button", text: "Confirm").click
    end

    step "view new appeal in Case Details page" do
      # Waiting for success message ensures time to process the substitution
      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_SUCCESS_TITLE

      appellant_substitution = AppellantSubstitution.find_by(source_appeal_id: appeal.id)
      new_appeal = appellant_substitution.target_appeal
      expect(page).to have_current_path("/queue/appeals/#{new_appeal.uuid}")

      # Verify that the Evidence Submission Window was stored correctly
      if docket_type.eql?("evidence_submission")
        # Ensure that our new window ends on specified date, accounting for user's time zone (not based on midnight UTC)
        window_task = EvidenceSubmissionWindowTask.find_by(appeal: new_appeal)
        expect(window_task.timer_ends_at).to be_between(
          evidence_submission_window_end_time - 1.day,
          evidence_submission_window_end_time + 1.day
        )
        expect(window_task.timer_ends_at.utc_offset).to eql(Time.zone.now.utc_offset)
      end

      # New appeal should have the same docket
      expect(page).to have_content appeal.stream_docket_number
      # Substitute claimant is shown
      expect(page).to have_content new_appeal.claimant.person.name
      expect(page).to have_content(/Relation to Veteran: (Child|Spouse)/)
      expect(page).to have_content(new_appeal.claimant.representative_name)
      expect(page).to have_content COPY::CASE_DETAILS_POA_SUBSTITUTE
      expect(page).to have_content COPY::CASE_DETAILS_POA_EXPLAINER

      # Substitution is shown on timeline
      expect(page).to have_content COPY::CASE_TIMELINE_APPELLANT_SUBSTITUTION
      expect(page).to have_content COPY::CASE_TIMELINE_APPELLANT_SUBSTITUTION_PROCESSED
    end

    step "verify items on original appeal" do
      visit "/queue/appeals/#{appeal.uuid}"

      expect(page).to_not have_content "+ Add Substitute"

      expect(page).to have_content COPY::SUBSTITUTE_APPELLANT_SOURCE_APPEAL_ALERT_DESCRIPTION
    end
  end
end
