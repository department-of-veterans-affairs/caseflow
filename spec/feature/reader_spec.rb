require "rails_helper"

RSpec.feature "Reader", focus: true do  
  let(:vacols_record) { Fakes::AppealRepository.appeal_remand_decided }

  # Currently the vbms_document_ids need to be set since they correspond to specific
  # files to load when we fetch content.
  let(:documents) do
    [
      Generators::Document.build(
        filename: "BVA Decision",
        type: "BVA Decision",
        received_at: 7.days.ago,
        vbms_document_id: 5
      ),
      Generators::Document.build(
        filename: "Form 9",
        type: "Form 9",
        received_at: 5.days.ago,
        vbms_document_id: 2
      )
    ]
  end

  let(:appeal) do
    Generators::Appeal.create(vacols_record: vacols_record, documents: documents)
  end

  context "Visit Reader" do
    let!(:current_user) do
      User.authenticate!(roles: ["System Admin"])
    end

    scenario "Add comment" do
      visit "/decision/review?vacols_id=#{appeal.vacols_id}"
      expect(page).to have_content("Caseflow Decision")

      click_on documents[0].filename
      expect(page).to have_content("Important Decision Document!!!")

      click_on "+ Add a Comment"
      find("#pageContainer1").click

      fill_in "addComment", with: "Foo"

      click_on "Save"
      expect(page).to have_content("Foo")

      expect(documents[0].reload.annotations.first.comment).to eq("Foo")

      click_on "Edit"
      fill_in "editComment", with: "Bar"

      click_on "Save"
      expect(page).to have_content("Bar")

      expect(documents[0].reload.annotations.first.comment).to eq("Bar")

      click_on "Delete"
      expect(page).to_not have_content("Bar")
      expect(documents[0].reload.annotations.count).to eq(0)
    end
  end
end