# frozen_string_literal: true

RSpec.feature("Correspondence Intake submission") do
  include CorrespondenceHelpers
  include RetryHelper
  let(:wait_time) { 30 }

  context "user associates correspondence with prior mail" do
    describe "success" do
      it "displays a success banner and links the correspondence" do
        visit_intake_form_with_correspondence_load
        associate_with_prior_mail_radio_options[:yes].click
        page.execute_script('
          document.querySelectorAll(".cf-form-checkbox input[type=\'checkbox\']").forEach((checkbox, index) => {
            if (index == 1) {
              checkbox.click();
            }
          });
        ')
        click_button("Continue")
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("You have successfully submitted a correspondence record")
        end
        expect(Correspondence.first.related_correspondences).to eq([Correspondence.third])
      end
    end
  end

  context "user selects completed mail tasks" do
    describe "success" do
      it "displays confirm submission" do
        visit_intake_form_step_2_with_appeals
        page.all(".cf-form-checkbox")[2].click
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("You have successfully submitted a correspondence record")
        end
      end
    end
  end

  context "user add tasks not related to an appeal" do
    describe "success" do
      before do
        seed_autotext_table
      end
      it "displays confirm submission" do
        visit_intake_form_step_2_with_appeals
        click_button("+ Add tasks")
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("addAutotext").click
        within find_by_id("autotextModal") do
          page.all(".cf-form-checkbox")[6].click
          find_by_id("Add-autotext-button-id-1").click
        end
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("You have successfully submitted a correspondence record")
        end
      end
    end

    describe "failure" do
      let(:mock_correspondence_intake_processor) do
        instance_double(
          CorrespondenceIntakeProcessor,
          process_intake: false
        )
      end

      before do
        allow(CorrespondenceIntakeProcessor).to receive(:new).and_return(mock_correspondence_intake_processor)
        require Rails.root.join("db/seeds/base.rb").to_s
        Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |f| require f }
        Seeds::Correspondence.new.create_auto_text_data
      end
      it "displays a failed submission error banner" do
        visit_intake_form_step_2_with_appeals
        click_button("+ Add tasks")
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("addAutotext").click
        within find_by_id("autotextModal") do
          page.all(".cf-form-checkbox")[6].click
          find_by_id("Add-autotext-button-id-1").click
        end
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("The correspondence's documents have failed")
        end
      end
    end
  end

  context "user adds tasks related to an appeal" do
    describe "success" do
      it "displays a success banner, links the appeal, and creates the task" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        page.find("#button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("content").fill_in with: "Correspondence Text"
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("You have successfully submitted a correspondence record")
        end
        # The interactions above chose last checkbox on the table which is the 15th appeal due to pagination settings.
        # If the pagination requirements change, this expectation will need to be updated.
        expect(Correspondence.first.appeals).to eq([Appeal.find(15)])
        expect(Correspondence.first.appeals[0].tasks.pluck(:type)).to include("ClearAndUnmistakeableErrorMailTask")
      end

      describe "with Docket Switch task added" do
        before do
          visit_intake_form_step_2_with_appeals
          existing_appeal_radio_options[:yes].click

          using_wait_time(wait_time) do
            within ".cf-case-list-table" do
              page.all(".cf-form-checkbox").last.click
            end
          end

          page.find("#button-addTasks").click
          all("#reactSelectContainer")[0].click
          find("div", exact_text: "Docket Switch").click
          find_by_id("content").fill_in with: "Correspondence Text"
          click_button("Continue")
          click_button("Submit")
          click_button("Confirm")
          using_wait_time(wait_time) do
            expect(page).to have_content("You have successfully submitted a correspondence record")
          end
        end

        it "creates DocketSwitchMailTask for Appeal and Corespondence" do
          # Creating DocketSwitchMailTask on appeal always generates a root DocketSwitchMailTask
          # CorrespondenceAppeal should only show the task it generates through intake workflow
          expect(DocketSwitchMailTask.all.count).to eq(2)
          appeal = Appeal.find(DocketSwitchMailTask.first.appeal_id)
          correspondence_appeal = CorrespondenceAppeal.find_by(appeal_id: appeal.id)
          expect(appeal.tasks.count { |e| e.instance_of?(DocketSwitchMailTask) }).to eq(2)
          expect(correspondence_appeal.tasks.count { |e| e.instance_of?(DocketSwitchMailTask) }).to eq(1)
        end

        it "allows InboundOpsTeam user to assign DocketSwitchMailTask to ClerkOfTheBoard organization" do
          docket_assigner = User.find(DocketSwitchMailTask.last.assigned_by_id)
          docket_assignee = Organization.find(DocketSwitchMailTask.last.assigned_to_id)
          expect(docket_assigner.organizations).to include(InboundOpsTeam)
          expect(docket_assignee.class).to eq(ClerkOfTheBoard)
        end
      end

      describe "with Cavc Correspondence Mail Task added" do
        before do
          visit_intake_form_step_2_with_appeals
          existing_appeal_radio_options[:yes].click

          using_wait_time(wait_time) do
            within ".cf-case-list-table" do
              page.all(".cf-form-checkbox").last.click
            end
          end

          page.find("#button-addTasks").click
          all("#reactSelectContainer")[0].click
          find("div", exact_text: "CAVC Correspondence").click
          find_by_id("content").fill_in with: "Correspondence Text"
          click_button("Continue")
          click_button("Submit")
          click_button("Confirm")
          using_wait_time(wait_time) do
            expect(page).to have_content("You have successfully submitted a correspondence record")
          end
        end

        it "creates CavcCorrespondenceMailTask for Appeal and Corespondence" do
          expect(CavcCorrespondenceMailTask.all.count).to eq(2)
          appeal = Appeal.find(CavcCorrespondenceMailTask.first.appeal_id)
          correspondence_appeal = CorrespondenceAppeal.find_by(appeal_id: appeal.id)
          expect(appeal.tasks.count { |e| e.instance_of?(CavcCorrespondenceMailTask) }).to eq(2)
          expect(correspondence_appeal.tasks.count { |e| e.instance_of?(CavcCorrespondenceMailTask) }).to eq(1)
        end

        it "allows InboundOpsTeam user to assign CavcCorrespondenceMailTask to CavcLitigationSupport organization" do
          assigner = User.find(CavcCorrespondenceMailTask.last.assigned_by_id)
          assignee = Organization.find(CavcCorrespondenceMailTask.last.assigned_to_id)
          expect(assigner.organizations).to include(InboundOpsTeam)
          expect(assignee.class).to eq(CavcLitigationSupport)
        end
      end
    end

    describe "failure" do
      it "displays a failure banner, and does not link appeal" do
        # this fails because the seed appeal has no root task
        visit_intake_form_step_2_with_appeals_without_initial_tasks
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        page.find("#button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("content").fill_in with: "Correspondence Text"
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("The correspondence's documents have failed to upload to the eFolder")
        end
        expect(Correspondence.first.appeals).to eq([])
      end
    end
  end

  context "user waives evidence submission window task on an appeal" do
    describe "success" do
      it "completes the evidence submission window task" do
        active_evidence_submissions_tasks
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          page.all(".checkbox-wrapper-1").find(".cf-form-checkbox").first.click
        end
        find("label", text: "Waive Evidence Window").click
        find_by_id("waiveReason").fill_in with: "test waive note"
        click_button("Continue")

        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("You have successfully submitted a correspondence record")
        end

        eswt = EvidenceSubmissionWindowTask.find_by(appeal_id: CorrespondenceAppeal.first.appeal_id)
        expect(eswt.status).to eq("completed")
      end
    end
  end

  context "user links appeals but does not add any tasks" do
    describe "success" do
      it "displays a success banner, links the appeal" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        click_button("Continue")
        click_button("Submit")
        click_button("Confirm")
        using_wait_time(wait_time) do
          expect(page).to have_content("You have successfully submitted a correspondence record")
        end
        # The interactions above chose last checkbox on the table which is the 15th appeal due to pagination settings.
        # If the pagination requirements change, this expectation will need to be updated.
        expect(Correspondence.first.appeals).to eq([Appeal.find(15)])
      end
    end
  end

  context "user adds tasks related to inactive appeals" do
    let(:tasks_json) { JSON.parse!(File.read("client/constants/QUEUE_INTAKE_FORM_TASK_TYPES.json")) }
    let(:inactive_appeal_tasks) { tasks_json["relatedToAppealInactive"] }
    let(:inactive_appeal_tasks_count) { tasks_json["relatedToAppealInactive"].length }
    let(:max_new_tasks) { 4 }
    let(:correspondence_appeals) { CorrespondenceAppeal.where(correspondence_id: Correspondence.first.id) }
    let(:created_tasks) { correspondence_appeals.map(&:tasks).flatten }
    let(:organization_assignments) do
      groups_by_organization = inactive_appeal_tasks.group_by { |e| e["value"]["assigned_to"] }
      groups_by_organization.each do |key, value|
        new_value = value.map { |v| v["value"]["klass"] }
        groups_by_organization[key] = new_value
      end
    end

    before do
      # Need to add user to BvaDispatch - new BvaDispatch tasks are automatically assigned to users
      BvaDispatch.singleton.add_user(create(:user))

      # Visit page with inactive appeals
      visit_intake_form_step_2_with_inactive_appeals
      existing_appeal_radio_options[:yes].click
      using_wait_time(wait_time) do
        within ".cf-case-list-table" do
          appeal_checkboxes = page.all(".cf-form-checkbox")[0, (inactive_appeal_tasks_count / max_new_tasks).ceil]
          appeal_checkboxes.each(&:click)
        end
      end

      # Add a new task for each existing related to inactive appeal task
      add_task_buttons = page.all("#button-addTasks")
      add_task_buttons.each { |button| max_new_tasks.times { button.click } }

      # Select each unique related to inactive appeal task
      react_select_containers = page.all("#reactSelectContainer")
      react_select_containers.each_with_index do |select_container, index|
        retry_when Capybara::ElementNotFound do
          using_wait_time(wait_time) do
            click_page_body
            select_container.click
            find("div", exact_text: inactive_appeal_tasks[index]["label"]).click
          end
        end
      end

      # Fill in all the required text boxes for all tasks
      task_text_content_boxes = page.all("textarea#content")
      task_text_content_boxes.each { |box| box.fill_in with: "Correspondence Text" }

      click_button("Continue")
      click_button("Submit")
      click_button("Confirm")
      using_wait_time(wait_time) do
        expect(page).to have_content("You have successfully submitted a correspondence record")
      end
    end

    it "tasks are created and assigned to proper organization without changing appeal root task" do
      created_task_strings = created_tasks.map { |task| task.class.to_s }
      klasses = inactive_appeal_tasks.map { |json_obj| json_obj["value"]["klass"] }
      expect(klasses).to eq(created_task_strings)

      created_tasks.each do |task|
        org_klass_string = Organization.find(task.assigned_to_id).class.to_s
        task_klass_string = task.class.to_s

        # BvaDispatch tasks are automatically assigned to a BvaDispatch user
        if organization_assignments["BvaDispatch"].include?(task_klass_string)
          expect(task.on_hold?).to eq(true)
        else
          expect(task.assigned?).to eq(true)
        end

        expect(task.assigned_to_type).to eq("Organization")
        expect(organization_assignments[org_klass_string]).to include(task_klass_string)
      end

      appeals = Correspondence.first.appeals
      appeals.each { |appeal| expect(appeal.active?).to eq(false) }
    end
  end
end
