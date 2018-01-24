require "rails_helper"

RSpec.feature "Queue" do
  before do
    Fakes::Initializer.load!
  end

  let(:vacols_record) {:remand_decided}
  let(:documents) {[]}
  let!(:issues) {[Generators::Issue.build]}
  let!(:current_user) do
    User.authenticate!(roles: ["System Admin"])
  end

  context "search for appeals using veteran id" do
    # Currently the vbms_document_ids need to be set since they correspond to specific
    # files to load when we fetch content.
    let(:documents) do
      [
        Generators::Document.create(
          filename: "My BVA Decision",
          type: "BVA Decision",
          received_at: 7.days.ago,
          vbms_document_id: 6,
          category_procedural: true,
          tags: [
            Generators::Tag.create(text: "New Tag1"),
            Generators::Tag.create(text: "New Tag2")
          ],
          description: Generators::Random.word_characters(50)
        ),
        Generators::Document.create(
          filename: "My Form 9",
          type: "Form 9",
          received_at: 5.days.ago,
          vbms_document_id: 4,
          category_medical: true,
          category_other: true
        ),
        Generators::Document.create(
          filename: "My NOD",
          type: "NOD",
          received_at: 1.day.ago,
          vbms_document_id: 3
        )
      ]
    end
    let(:appeal) do
      Generators::Appeal.build(vbms_id: "123456789S", vacols_record: vacols_record, documents: documents)
    end

    scenario "with no appeals" do
      visit "/queue"
      fill_in "searchBar", with: "obviouslyfakecaseid"

      click_on "Search"

      expect(page).to have_content("Veteran ID not found")
    end

    scenario "one appeal found" do
      visit "/queue"
      fill_in "searchBar", with: (appeal.vbms_id + "\n")

      expect(page).to have_content("Select claims folder")
      expect(page).to have_content("Not seeing what you expected? Please send us feedback.")
      appeal_options = find_all(".cf-form-radio-option")
      expect(appeal_options.count).to eq(1)

      expect(appeal_options[0]).to have_content("Veteran #{appeal.veteran_full_name}")
      expect(appeal_options[0]).to have_content("Veteran ID #{appeal.vbms_id}")
      expect(appeal_options[0]).to have_content("Issues")
      expect(appeal_options[0].find_all("li").count).to eq(appeal.issues.size)

      appeal_options[0].click
      click_on "Okay"

      expect(page).to have_content(appeal.veteran_full_name + "'s Claims Folder")
    end
  end
end
