# frozen_string_literal: true

feature "Unrecognized appellants", :postgres do
  let(:veteran_file_number) { "123412345" }
  let!(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number, first_name: "Ed", last_name: "Merica")
  end

  let(:appeal_with_unrecognized_appellant) do
    create(
      :appeal,
      has_unrecognized_appellant: true,
      veteran: veteran,
      veteran_is_not_claimant: true
    )
  end

  let(:appeal_with_recognized_appellant) do
    create(
      :appeal,
      veteran_is_not_claimant: true,
      number_of_claimants: 1
    )
  end

  let!(:user) do
    create(:user, full_name: "Test User")
  end

  before do
    User.authenticate!(user: user)
  end

  context "with edit_unrecognized_appellant" do
    before { FeatureToggle.enable!(:edit_unrecognized_appellant) }
    after { FeatureToggle.disable!(:edit_unrecognized_appellant) }
    it "allows for editing of the first name of the unrecognized appellant" do
      visit "/queue/appeals/#{appeal_with_unrecognized_appellant.uuid}"
      click_on "Edit Information"

      expect(page).to have_content("Edit Appellant Information")
      expect(find("#firstName").value).to eq "Jane"
      expect(find("#lastName").value).to eq "Smith"

      fill_in "First name", with: ""
      expect(page).to have_button("Save", disabled: true)

      fill_in "First name", with: "Updated First Name"
      click_on "Save"
      expect(page).to have_current_path("/queue/appeals/#{appeal_with_unrecognized_appellant.uuid}")

      ua = appeal_with_unrecognized_appellant.claimant.unrecognized_appellant
      expect(ua.first_name).to eq("Updated First Name")
      expect(ua.versions.count).to eq(2)
      expect(ua.first_version.first_name).to eq("Jane")
      expect(page).to have_content("Name: Updated First Name Smith")
      expect(page).to have_content(format(COPY::EDIT_UNRECOGNIZED_APPELLANT_SUCCESS_ALERT_TITLE
        .tr("(", "{").gsub(")s", "}"), appellantName: ua.name))
      expect(page).to have_content(COPY::EDIT_UNRECOGNIZED_APPELLANT_SUCCESS_ALERT_MESSAGE)
    end

    it "allows for updating the relationship of the unrecognized appellant" do
      visit "/queue/appeals/#{appeal_with_unrecognized_appellant.uuid}"
      click_on "Edit Information"

      expect(page).to have_content("Edit Appellant Information")
      # Check that form is prepopulated with existing appellant information
      fill_in("Relationship to the Veteran", with: "Other").send_keys :enter
      within_fieldset("Is the claimant an organization or individual?") do
        find("label", text: "Organization", match: :prefer_exact).click
      end
      fill_in "Organization name", with: "Organization 1"
      click_on "Save"
      expect(page).to have_current_path("/queue/appeals/#{appeal_with_unrecognized_appellant.uuid}")
      ua = appeal_with_unrecognized_appellant.claimant.unrecognized_appellant
      expect(ua.name).to eq("Organization 1")
      expect(ua.party_type).to eq("organization")
      expect(ua.versions.count).to eq(2)
      expect(ua.first_version.first_name).to eq("Jane")
      expect(page).to have_content("Relation to Veteran: Other")
      expect(page).to have_content(format(COPY::EDIT_UNRECOGNIZED_APPELLANT_SUCCESS_ALERT_TITLE
                                          .tr("(", "{").gsub(")s", "}"), appellantName: ua.name))
      expect(page).to have_content(COPY::EDIT_UNRECOGNIZED_APPELLANT_SUCCESS_ALERT_MESSAGE)
    end

    it "renders error alert when update fails" do
      allow_any_instance_of(UnrecognizedAppellantsController).to receive(:update).and_raise("Internal Server Error")

      visit "/queue/appeals/#{appeal.uuid}"
      click_on "Edit Information"

      expect(page).to have_content("Edit Appellant Information")
      expect(page).to have_current_path("/queue/appeals/#{appeal.uuid}/edit_appellant_information")
      find("button", text: "Save").click
      expect(page).to have_content(COPY::EDIT_UNRECOGNIZED_APPELLANT_FAILURE_ALERT_TITLE)
    end
  end
  context "with attorney unrecognized appellant" do
    before { FeatureToggle.enable!(:edit_unrecognized_appellant) }
    after { FeatureToggle.disable!(:edit_unrecognized_appellant) }

    it "should not show edit button on case details screen" do
      visit "/queue/appeals/#{appeal_with_recognized_appellant.uuid}"
      expect(page).to_not have_content("Edit Information")
    end

    it "should not show the listed attorney name dropdown on the edit screen" do
      visit "/queue/appeals/#{appeal_with_unrecognized_appellant.uuid}"
      click_on "Edit Information"

      fill_in("Relationship to the Veteran", with: "Attorney (previously or currently)").send_keys :enter

      expect(page).to_not have_content("Claimant's name")

      fill_in "First name", with: "Updated First Name"
      click_on "Save"

      expect(page).to have_current_path("/queue/appeals/#{appeal_with_unrecognized_appellant.uuid}")
      ua = appeal_with_unrecognized_appellant.claimant.unrecognized_appellant
      expect(ua.first_name).to eq("Updated First Name")
      expect(ua.versions.count).to eq(2)
      expect(page).to have_content("Name: Updated First Name Smith")
    end
  end
end
