# frozen_string_literal: true

RSpec.feature("The Correspondence Intake page") do
  let(:organization) { InboundOpsTeam.singleton }
  let(:mail_user) { User.authenticate!(roles: ["Mail Team"]) }
  let(:correspondence) { create :correspondence }
  let(:correspondence_intake_task) do
    create(
      :correspondence_intake_task,
      appeal: correspondence,
      appeal_type: Correspondence.name,
      assigned_to: mail_user
    )
  end

  before do
    # reload in case of controller validation triggers before data created
    correspondence_intake_task.reload
    organization.add_user(mail_user)
    mail_user.reload
  end

  context "intake form shell" do
    before :each do
      FeatureToggle.enable!(:correspondence_queue)
      visit "/queue/correspondence/#{correspondence.uuid}/intake"
    end

    it "the intake page exists" do
      expect(page).to have_current_path("/queue/correspondence/#{correspondence.uuid}/intake")
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
      position = 0
      [0, 1, 2].each do |aux|
        position = aux
        click_on("+ Add letter")
        expect(page).to have_button("Continue", disabled: true)
      end
      if position == 2
        expect(page).to have_button("Continue", disabled: true)
        expect(page).to have_button("+ Add letter", disabled: true)
      end
    end

    it "Create Response letter" do
      click_on("+ Add letter")
      expect(page).to have_field("Date sent")
      mydate = page.all("#date-set")
      expect(mydate[0].value == Time.zone.today.strftime("%Y-%m-%d"))

      page.should has_selector?("Letter type")
      page.should has_selector?("Letter title", visible: false)
      page.should has_selector?("Letter subcategory", visible: false)
      page.should has_selector?("Letter subcategory reason", visible: false)

      radio_choices = page.all(".cf-form-radio-option > label", visible: false)
      expect(radio_choices[0]).to have_content("65 days")
      expect(radio_choices[1]).to have_content("No response window")
      expect(radio_choices[2]).to have_content("Custom")

      expect(page).to have_button("Remove letter")
    end

    it "Add values to response letter for response window = No respondense windows" do
      click_on("+ Add letter")

      dropdowns = page.all(".cf-select__control")
      dropdowns[0].click
      dropdowns[0].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "Pre-docketing"
      ).click
      expect(page).to have_field("Letter title", readonly: false)

      dropdowns[1].click
      dropdowns[1].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "Intake 10182 Recv Needs AOJ Development"
      ).click
      expect(page).to have_field("Letter subcategory", readonly: false)

      radio_choices = page.all(".cf-form-radio-option> label.disabled", visible: true)
      radio_choices.each do |opt|
        opt.text.not_eq("No response window")
      end

      dropdowns[2].click
      dropdowns[2].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "Issues(s) is VHA"
      ).click
      expect(page).to have_field("Letter subcategory reason", readonly: false)

      dropdowns[3].click
      dropdowns[3].sibling(".cf-select__menu").find("div .cf-select__option", text: "N/A").click
    end

    it "Add values to response letter for response window =  65 day" do
      click_on("+ Add letter")

      dropdowns = page.all(".cf-select__control")
      dropdowns[0].click
      dropdowns[0].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "General"
      ).click
      expect(page).to have_field("Letter title", readonly: false)

      dropdowns[1].click
      dropdowns[1].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "Intake AMA Corrective App Receipt"
      ).click
      expect(page).to have_field("Letter subcategory", readonly: false)

      radio_choices = page.all(".cf-form-radio-option> label.disabled", visible: true)

      radio_choices.each do |opt|
        opt.text.to_eq("No response window")
      end

      dropdowns[2].click
      dropdowns[2].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "N/A"
      ).click
      expect(page).to have_field("Letter subcategory reason", readonly: false)

      dropdowns[3].click
      dropdowns[3].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "N/A"
      ).click
    end

    it "Add values to response letter for response window =  Custom" do
      click_on("+ Add letter")

      dropdowns = page.all(".cf-select__control")
      dropdowns[0].click
      dropdowns[0].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "General"
      ).click
      expect(page).to have_field("Letter title", readonly: false)

      dropdowns[1].click
      dropdowns[1].sibling(".cf-select__menu").find(
        "div .cf-select__option", text: "Intake AMA Corrective App Receipt"
      ).click
      expect(page).to have_field("Letter subcategory", readonly: false)

      radio_choices = page.all(".cf-form-radio-option> label")
      radio_choices[2].click
      page.has_field?("Number of days (Value must be between 0 and 65)")

      radio_choices[0].click
      page.has_no_field?("Number of days (Value must be between 0 and 65)")
    end
  end
end
