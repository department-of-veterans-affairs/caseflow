# frozen_string_literal: true

RSpec.feature("Tasks related to an existing Appeal - Correspondence Intake page step 2.3") do
  include CorrespondenceHelpers
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

      it "continue button is inactive if a checkbox is checked" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click
        page.all(".cf-form-checkbox").last.click

        expect(page.has_button?("Continue")).to be(false)
      end
    end

    describe "table of existing appeals" do

      it "table displays pagination summary" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(15) do
          expect(page).to have_content("Viewing 1-5 of 13 total")
        end
      end

      it "table has column headers" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(10) do
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

        using_wait_time(10) do
          page.all('.cf-pdf-external-link-icon')[0].click
        end
        using_wait_time(10) do
          page.switch_to_window(page.windows.last)
          expect(current_path).to have_content('/queue/appeals')
        end
      end

      it "table displays 5 items per page" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click
         using_wait_time(10) do
          within(page.all(".cf-pagination")[0]) do
            expect(find_all(".cf-form-checkbox").count).to eq(5)
          end
        end
      end

      it "table incorporates pagination navigation" do
        visit_intake_form_step_2_with_appeals

        existing_appeal_radio_options[:yes].click

        using_wait_time(10) do
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

        using_wait_time(10) do
          page.all(".cf-form-checkbox").last.click
        end

        existing_appeal_radio_options[:no].click

        existing_appeal_radio_options[:yes].click

        expect(page.all(".cf-form-checkbox").last.checked?).to be(false)
      end
    end
  end
end
