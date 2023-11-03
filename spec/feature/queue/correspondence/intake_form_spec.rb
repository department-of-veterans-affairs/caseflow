# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  context "intake form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      User.authenticate!(roles: ["Mail Intake"])
      @correspondence_uuid = "123456789"
      visit "/queue/correspondence/#{@correspondence_uuid}/intake"
    end

    it "the intake page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{@correspondence_uuid}/intake")
    end

    it "displays the correspondence header" do
      expect(page).to have_content("Add Related Correspondence")
    end

    it "displays the added related instruction string" do
      expect(page).to have_content("Add any related correspondence to the mail package that is in progress.")
    end

    it "displays the Associate with prior Mail header" do
      expect(page).to have_content("Associate with prior Mail")
    end

    it "displays the question about correspondence related to prior mail string" do
      expect(page).to have_content("Is this correspondence related to prior mail?")
    end

    it "shows related to prior mail yes & no radio buttons" do
      radio_choices = page.all(".cf-form-radio-option > label")
      expect(radio_choices[0]).to have_content("Yes")
      expect(radio_choices[1]).to have_content("No")
    end
  end
end
