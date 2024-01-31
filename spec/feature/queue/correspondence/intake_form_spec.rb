# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  let(:organization) { MailTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }

  before do
    organization.add_user(mail_user)
    mail_user.reload
  end

  context "intake form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
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

    it "displays Response Letter header" do
      expect(page).to have_content("Response Letter")
      expect(page).to have_content("+ Add letter")
    end

    it "create response letter only 3 times" do
      for i in 0 ..2
        click_on("+ Add letter")
        expect(page).to have_button("Continue", disabled: true)
      end
      if (i == 2)
        expect(page).to have_button("Continue", disabled: true)
        expect(page).to have_button("+ Add letter", disabled: true)
      end
    end

    it "Create Response letter" do
      click_on("+ Add letter")
      expect(page).to have_field("Date sent")
      # expect(page).to have_content(Date.today.strftime("%m/%d/%Y"))
      page.should has_selector?("Letter type")
      page.should has_selector?("Letter title", visible: false)
      page.should has_selector?("Letter subcategory", visible: false)
      page.should has_selector?("Letter subcategory reason", visible: false)

      radio_choices = page.all(".cf-form-radio-option > label",  visible:false)
      expect(radio_choices[0]).to have_content("65 days")
      expect(radio_choices[1]).to have_content("No response window")
      expect(radio_choices[2]).to have_content("Custom")

      expect(page).to have_button("Remove letter")
    end

    it "Add values to response letter for No respondense windows" do
      click_on("+ Add letter")

      dropdowns = page.all(".cf-select__control")
      dropdowns[0].click
      dropdowns[0].sibling(".cf-select__menu").find("div .cf-select__option", text: "Pre-docketing").click
      expect(page).to have_field("Letter title", readonly: false)

      dropdowns[1].click
      dropdowns[1].sibling(".cf-select__menu").find("div .cf-select__option", text: "Intake 10182 Recv Needs AOJ Development").click
      expect(page).to have_field("Letter subcategory", readonly: false)

      # radio_choices = page.all(".cf-form-radio-option > label")
      # expect(radio_choices[1]).to have_content("No response window").checked? eq

      dropdowns[2].click
      dropdowns[2].sibling(".cf-select__menu").find("div .cf-select__option", text: "Issues(s) is VHA").click
      expect(page).to have_field("Letter subcategory reason", readonly: false)

      dropdowns[3].click
      dropdowns[3].sibling(".cf-select__menu").find("div .cf-select__option", text: "N/A").click
    end
  end
end
