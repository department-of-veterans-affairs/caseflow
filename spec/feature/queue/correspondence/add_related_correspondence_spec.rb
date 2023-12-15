# frozen_string_literal: true

RSpec.feature("Add Related Correspondence - Correspondence Intake page") do
  include CorrespondenceHelpers

  let(:organization) { MailTeam.singleton }
  let(:bva_user) { User.authenticate!(roles: ["Mail Intake"]) }

  before(:each) do
    organization.add_user(bva_user)
    bva_user.reload
  end

  context "No related correspondence" do

    it "Displays the expected content" do
      visit_intake_form

      expect(page).to have_content("Add Related Correspondence")
      expect(page).to have_content("Add any related correspondence to the mail package that is in progress.")
      expect(page).to have_content("Is this correspondence related to prior mail?")
      expect(page).to have_content("Associate with prior Mail")
      expect(associate_with_prior_mail_radio_options[:yes]).to have_text("Yes")
      expect(associate_with_prior_mail_radio_options[:no]).to have_text("No")
    end

    it "Continue button is active" do
      visit_intake_form

      expect(page.has_button?("Continue")).to be(true)
    end
  end

  context "Yes - related correspondence" do
    describe "the continue button" do
      it "continue button is inactive if no checkboxes are checked" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        expect(page.has_button?("Continue")).to be(false)
      end

      it "continue button is active if a checkbox is checked" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click
        page.all(".cf-form-checkbox")[1].click

        expect(page.has_button?("Continue")).to be(true)
      end
    end

    describe "table of prior correspondences" do
      it "table displays instructions" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        expect(page).to have_content("Please select the prior mail to link to this correspondence")
      end

      it "table displays pagination summary" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        expect(page).to have_content("Viewing 1-15 of 54 total")
      end

      it "table has column headers" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        expect(page).to have_content("VA DOR")
        expect(page).to have_content("Source Type")
        expect(page).to have_content("Package Document Type")
        expect(page).to have_content("Correspondence Type")
        expect(page).to have_content("Notes")
      end

      it "rows display correspondence info" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        expect(page).to have_content("1/1/2023")
        expect(page).to have_content("Mail")
        expect(page).to have_content("15")
        expect(page).to have_content("9")
        expect(page).to have_content("This is a note from CMP")
      end

      it "table displays 15 items per page" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click
        expect(find_all(".cf-form-checkbox").count).to eq(15)
      end

      it "table incorporates pagination navigation" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        expect(page.has_button?("Previous")).to be(false)
        expect(page.has_button?("Next")).to be(true)

        click_button("Next")

        expect(page.has_button?("Previous")).to be(true)
        expect(page.has_button?("Next")).to be(true)
        expect(page).to have_content("Viewing 16-30 of 54 total")

        click_button("4")

        expect(page.has_button?("Next")).to be(false)
        expect(page.has_button?("Previous")).to be(true)
        expect(page).to have_content("Viewing 46-54 of 54 total")
      end

      it "Checkbox values persist through page navigation" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        page.all(".cf-form-checkbox")[0..5].each { |cb| cb.set(true) }

        click_button("Next")

        click_button("Previous")

        expect(page.has_button?("Continue")).to be(true)
      end

      it "Checkbox values are reset if user clicks No and then Yes" do
        visit_intake_form_with_correspondence_load

        associate_with_prior_mail_radio_options[:yes].click

        page.all(".cf-form-checkbox")[0..5].each { |cb| cb.set(true) }

        associate_with_prior_mail_radio_options[:no].click

        associate_with_prior_mail_radio_options[:yes].click

        expect(page.has_button?("Continue")).to be(false)
      end
    end
  end
end
