# frozen_string_literal: true

RSpec.feature("Tasks related to an existing Appeal - Correspondence Intake page step 2.3") do
  include CorrespondenceHelpers
  let(:organization) { MailTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }

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
        page.all(".cf-form-checkbox").last.click

        expect(page.has_button?("Continue")).to be(true)
      end
    end

    describe "table of existing appeals" do
      it "table displays pagination summary" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(20) do
          expect(page).to have_content("Viewing 1-5 of 13 total")
        end
      end

      it "table has column headers" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(20) do
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

        using_wait_time(20) do
          page.all(".cf-pdf-external-link-icon")[0].click
        end
        using_wait_time(10) do
          page.switch_to_window(page.windows.last)
          expect(current_path).to have_content("/queue/appeals")
        end
      end

      it "table displays 5 items per page" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(20) do
          within(page.all(".cf-pagination")[0]) do
            expect(find_all(".cf-form-checkbox").count).to eq(5)
          end
        end
      end

      it "table incorporates pagination navigation" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(20) do
          expect(page.has_button?("Previous")).to be(false)
          expect(page.has_button?("Next")).to be(true)
        end

        click_button("Next")

        expect(page.has_button?("Previous")).to be(true)
        expect(page.has_button?("Next")).to be(true)
        expect(page).to have_content("Viewing 6-10 of 13 total")

        click_button("3")

        expect(page.has_button?("Next")).to be(false)
        expect(page.has_button?("Previous")).to be(true)
        expect(page).to have_content("Viewing 11-13 of 13 total")
      end

      it "Checkbox values are reset if user clicks No and then Yes" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(20) do
          page.all(".cf-form-checkbox").last.click
        end

        existing_appeal_radio_options[:no].click

        existing_appeal_radio_options[:yes].click

        expect(page.all(".cf-form-checkbox").last.checked?).to be(false)
      end

      it "table displays active evidence submission window tasks related to the existing appeal from the checkbox" do
        active_evidence_submissions_tasks

        existing_appeal_radio_options[:yes].click

        using_wait_time(20) do
          page.all(".checkbox-wrapper-1").find(".cf-form-checkbox").first.click
        end
        expect(page).to have_selector("#react-select-2-input[disabled]")
        expect(page).to have_text("Evidence Window Submission Task")
        expect(page).to have_text("Provide context and instruction on this task")
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
          unformatted_id = page.all(".cf-form-checkboxes").first[:class]
          formatted_id = unformatted_id.split("-")[2].split(" ")[0]
          expect find_by_id(formatted_id, visible: false).checked?
        end
      end

      it "Adds and removes a task from the linked appeal" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(15) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-1").click
        find_by_id("content").fill_in with: "Correspondence Text"

        # will need to add another "remove task" test if only one task exists.
        # currently a bug exists where "remove task" option does not show with a single task
        expect(page.all("#button-Remove").length).to_not eq(2)

        page.all("#button-addTasks").first.click
        expect(page.all("#button-Remove").length).to eq(2)

        page.all("#button-Remove").last.click
        expect(page.all("#button-Remove").length).to_not eq(2)
      end

      it "Prevents user from clicking continue if task name or text isn't filled out" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(15) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
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
        using_wait_time(15) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        find_by_id("content").fill_in with: "Correspondence Text"
        expect((all("#reactSelectContainer")[0]).text).to include("Other motion")

        page.all("#button-addTasks").first.click
        all("#reactSelectContainer")[1].click
        find_by_id("react-select-3-option-15").click
        all("textarea")[1].fill_in with: "Correspondence Text"
        expect(all("#reactSelectContainer")[1].text).to include("Other motion")

        page.all("#button-addTasks").first.click
        all("#reactSelectContainer")[2].click
        find_by_id("react-select-4-option-15").click
        all("textarea")[2].fill_in with: "Correspondence Text"
      end

      it "Unlinks the appeal when the unlink appeal button is clicked" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(15) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").last.click
          end
        end
        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        find_by_id("content").fill_in with: "Correspondence Text"
        expect((find_all("#reactSelectContainer")).length).to eq(1)
        find_all(".fa.fa-unlink").last.click
        expect((find_all("#reactSelectContainer")).length).to eq(0)
      end

      it "Unlinks only one appeal if multiple are selected when the unlink appeal button is clicked" do
        visit_intake_form_step_2_with_appeals
        existing_appeal_radio_options[:yes].click
        using_wait_time(15) do
          within ".cf-case-list-table" do
            page.all(".cf-form-checkbox").first.click
            page.all(".cf-form-checkbox").last.click
          end
        end

        all("#reactSelectContainer")[0].click
        find_by_id("react-select-2-option-15").click
        all("textarea")[0].fill_in with: "Correspondence Text"

        all("#reactSelectContainer")[1].click
        find_by_id("react-select-3-option-15").click
        all("textarea")[1].fill_in with: "Correspondence Text"

        expect((find_all("#reactSelectContainer")).length).to eq(2)
        find_all(".fa.fa-unlink").last.click
        expect((find_all("#reactSelectContainer")).length).to eq(1)
      end
    end
  end
end
