# frozen_string_literal: true

RSpec.feature("Tasks related to an existing Appeal - Correspondence Intake page step 2.3") do
  include CorrespondenceHelpers
  let(:organization) { InboundOpsTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }
  let(:wait_time) { 30 }

  before do
    organization.add_user(mail_user)
    mail_user.reload
  end

  context "Correspondence is not related to an existing appeal" do
    it "Displays the expected content" do
      visit_intake_form_step_2_with_appeals

      expect(page).to have_content("Tasks related to an existing Appeal")
      expect(page).to have_content("Is this correspondence related to an existing appeal?")
      expect(existing_appeal_radio_options[:yes]).to have_text("Yes")
      expect(existing_appeal_radio_options[:no]).to have_text("No")
    end

    it "Continue button is active" do
      visit_intake_form_step_2_with_appeals

      expect(page.has_button?("Continue")).to be(true)
    end
  end

  context "Yes - related existing Appeals" do
    describe "the continue button" do
      it "continue button is active if a checkbox is checked" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click
        page.all(".checkbox-column-inline-style").last.click

        expect(page.has_button?("Continue")).to be(true)
      end
    end

    describe "table of existing appeals" do
      it "table displays pagination summary" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          expect(page).to have_content("Viewing 1-15 of 20 total")
        end
      end

      it "table has column headers" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          expect(page).to have_content("Docket")
          expect(page).to have_content("Appellant Name")
          expect(page).to have_content("Status")
          expect(page).to have_content("Types")
          expect(page).to have_content("Number of Issues")
          expect(page).to have_content("Decision Date")
          expect(page).to have_content("Assigned To")
        end
      end

      it "displays link to case details page" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          page.all(".cf-pdf-external-link-icon")[0].click
        end
        using_wait_time(wait_time) do
          page.switch_to_window(page.windows.last)
          expect(current_path).to have_content("/queue/appeals")
        end
      end

      it "table displays 15 items per page" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          within(page.all(".cf-pagination")[0]) do
            expect(find_all(".checkbox-column-inline-style").count).to eq(15)
          end
        end
      end

      it "table incorporates pagination navigation" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          expect(page.has_button?("Previous")).to be(false)
          expect(page.has_button?("Next")).to be(true)
        end

        click_button("Next")

        expect(page.has_button?("Previous")).to be(true)
        expect(page.has_button?("Next")).to be(false)
        expect(page).to have_content("Viewing 16-20 of 20 total")

        click_button("2")

        expect(page.has_button?("Next")).to be(false)
        expect(page.has_button?("Previous")).to be(true)

        click_button("1")
        expect(page).to have_content("Viewing 1-15 of 20 total")
      end

      it "Checkbox values are reset if user clicks No and then Yes" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          page.all(".cf-form-checkbox").last.click
        end

        existing_appeal_radio_options[:no].click

        existing_appeal_radio_options[:yes].click

        expect(page.all(".cf-form-checkbox").last.checked?).to be(false)
      end

      it "table displays active evidence submission window tasks related to the existing appeal from the checkbox" do
        active_evidence_submissions_tasks

        existing_appeal_radio_options[:yes].click

        using_wait_time(wait_time) do
          page.all(".checkbox-wrapper-1").find(".cf-form-checkbox").first.click
        end
        expect(page).to have_selector("#react-select-2-input[disabled]")
        expect(page).to have_text("Evidence Window Submission Task")
        expect(page).to have_text("Provide context and instructions on this task")
        field = find_field("content", disabled: true)
        expect(field.tag_name).to eq("textarea")
        checkbox_label = "Waive Evidence Window"
        find("label", text: checkbox_label).click
        find_by_id("waiveReason").fill_in with: "test waive note"
        all("#reactSelectContainer").last.click
        expect(page).to have_button("button-continue", disabled: false)
      end
    end

    describe "Linking and unlinking existing appeals" do
      it "Clicks an appeal from the table" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        page.should has_selector?("Existing Appeals")

        within find(".cf-case-list-table") do
          page.all(".cf-form-checkbox").first.click
          using_wait_time(wait_time) do
            unformatted_id = page.all(".cf-form-checkboxes").first[:class]
            formatted_id = unformatted_id.split("-")[2].split(" ")[0]
            expect find_by_id(formatted_id, visible: false).checked?
          end
        end
      end

      it "Adds and removes a task from the linked appeal" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end

        find_by_id("button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("content").fill_in with: "Correspondence Text"

        expect(page.all("#button-Remove").length).to eq(1)
        page.all("#button-Remove").first.click
        expect(page.all("#button-Remove").length).to eq(0)
      end

      it "Adds and removes multiple tasks from the linked appeal" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        find_by_id("button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("content").fill_in with: "Correspondence Text"

        expect(page.all("#button-Remove").length).to eq(1)
        page.all("#button-addTasks").first.click
        expect(page.all("#button-Remove").length).to eq(2)

        page.all("#button-Remove").last.click
        expect(page.all("#button-Remove").length).to eq(1)
        page.all("#button-Remove").first.click
        expect(page.all("#button-Remove").length).to eq(0)
      end

      it "Prevents user from clicking continue if task name or text isn't filled out" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        using_wait_time(wait_time) do
          find_by_id("button-addTasks").click
        end
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        expect(page).to have_button("button-continue", disabled: true)

        all("textarea")[0].fill_in with: "Correspondence Text"
        expect(page).to have_button("button-continue", disabled: false)
        page.all("#button-addTasks").first.click
        all("textarea")[1].fill_in with: "Correspondence Text"
        expect(page).to have_button("button-continue", disabled: true)

        all("#reactSelectContainer")[1].click
        find_by_id("react-select-3-option-15").click
        expect(page).to have_button("button-continue", disabled: false)
      end

      it "Prevents other motion tasks from being added 3 times" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        find_by_id("button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        find_by_id("content").fill_in with: "Correspondence Text"
        expect((all("#reactSelectContainer")[0]).text).to include("Other Motion")

        page.all("#button-addTasks").first.click
        all("#reactSelectContainer")[1].click
        find_by_id("react-select-3-option-15").click
        all("textarea")[1].fill_in with: "Correspondence Text"
        expect(all("#reactSelectContainer")[1].text).to include("Other Motion")

        page.all("#button-addTasks").first.click
        all("#reactSelectContainer")[2].click
        find_by_id("react-select-4-option-15").click
        all("textarea")[2].fill_in with: "Correspondence Text"
      end

      it "Unlinks the appeal when the unlink appeal button is clicked" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        find_by_id("button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        find_by_id("content").fill_in with: "Correspondence Text"
        expect(find_all("#reactSelectContainer").length).to eq(1)
        find_all(".fa.fa-unlink").last.click
        expect(find_all("#reactSelectContainer").length).to eq(0)
      end

      it "Unlinks only one appeal if multiple are selected when the unlink appeal button is clicked" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").first.click
            page.all(".cf-form-checkbox").last.click
          end
        end

        find_all("#button-addTasks").first.click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        all("textarea")[0].fill_in with: "Correspondence Text"

        find_all("#button-addTasks").last.click
        all("#reactSelectContainer")[1].click
        find_by_id("react-select-3-option-15").click
        all("textarea")[1].fill_in with: "Correspondence Text"

        expect(find_all("#reactSelectContainer").length).to eq(2)
        find_all(".fa.fa-unlink").last.click
        expect(find_all("#reactSelectContainer").length).to eq(1)
      end
    end

    describe "tasks related to an existing appeal that is inactive" do
      it "displays inactive appeals in the table of tasks related" do
        visit_intake_form_step_2_with_inactive_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          expect(page).to have_content("Existing Appeals")
          expect(page).to have_content("Viewing 1-10 of 10 total")
        end
      end

      it "hides irrelevant task options for tasks related to an appeal with a root task of closed" do
        visit_intake_form_step_2_with_inactive_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        find_by_id("button-addTasks").click
        all("#reactSelectContainer")[0].click
        expect(page).to have_content("CAVC Correspondence")
        expect(page).to_not have_content("Change Of Address")

        find_by_id("react-select-2-option-7").click
        find_by_id("content").fill_in with: "Correspondence Text"
        expect((all("#reactSelectContainer")[0]).text).to include("Other Motion")
      end

      it "verifies logic still works for which tasks can be duplicated" do
        visit_intake_form_step_2_with_inactive_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(wait_time) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        find_by_id("button-addTasks").click
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-0").click
        all("textarea")[0].fill_in with: "Correspondence Text"
        expect((all("#reactSelectContainer")[0]).text).to include("CAVC Correspondence")

        page.all("#button-addTasks").first.click
        all("#reactSelectContainer")[1].click
        expect(all("#reactSelectContainer")[1].text).to_not include("CAVC Correspondence")

        find_by_id("react-select-3-option-6").click
        all("textarea")[1].fill_in with: "Correspondence Text"
        expect(all("#reactSelectContainer")[1].text).to include("Other Motion")

        page.all("#button-addTasks").first.click
        all("#reactSelectContainer")[2].click
        find_by_id("react-select-4-option-6").click
        all("textarea")[2].fill_in with: "Correspondence Text"
        expect((all("#reactSelectContainer")[2]).text).to include("Other Motion")
      end
    end
  end
end
