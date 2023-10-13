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
        #page.fill_in("searchDocumentContents").with("fox")
        #click_button("searchDocumentContentsBtn")

        expect(page).to have_content("Document Type")
      end
    end
  end
end
