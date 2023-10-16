# frozen_string_literal: true

RSpec.feature "Reader", :all_dbs do
  let(:documents) do
    [
      Generators::Document.create,
      Generators::Document.create,
      Generators::Document.create
    ]
  end
  let(:appeal) do
    Generators::LegacyAppealV2.create(
      documents: documents,
      case_issue_attrs: [
        { issdc: "1" },
        { issdc: "A" },
        { issdc: "3" },
        { issdc: "D" }
      ]
    )
  end

  before do
    User.authenticate!(roles: ["Reader"])
  end

  feature "Document content search" do
    background do
      visit "/reader/appeal/#{appeal.vacols_id}/documents"
    end

    context "when search results exist" do
      before do
        allow(ClaimEvidenceService).to receive(:get_ocr_document).
          and_return("the quick brown fox", "peter piper picked")
      end

      it "displays the correct filtering message" do
        page.fill_in("fetchDocumentsInput", with: "fox")
        click_button("fetchDocumentContentsButton")

        expect(page).to have_content("Filtering by: Document Contents")
        expect(page.all("table tbody#documents-table-body tr").count).to eq 1
      end
    end

    context "when search results do not exist" do
      before do
        allow(ClaimEvidenceService).to receive(:get_ocr_document).
          and_return("In a hole in the ground there lived a hobbit")
      end

      it "displays the correct filtering message" do
        page.fill_in("fetchDocumentsInput", with: "balrog")
        click_button("fetchDocumentContentsButton")

        expect(page).to have_content("Filtering by: Document Contents")
        expect(page.all("table tbody#documents-table-body tr").count).to eq 0
      end
    end
  end
end
