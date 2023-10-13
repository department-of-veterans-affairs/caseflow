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

    it "displays the correct filtering message" do
      expect(page).to have_content("Document Type")
    end
  end
end
