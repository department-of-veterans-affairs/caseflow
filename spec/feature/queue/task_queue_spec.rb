require "rails_helper"

RSpec.feature "Task queue" do
  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:queue_phase_two)
  end

  after do
    FeatureToggle.disable!(:queue_phase_two)
  end

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
  let(:vacols_record) { :remand_decided }
  let(:appeals) do
    [
      Generators::LegacyAppeal.build(
        vbms_id: "123456789S",
        vacols_record: vacols_record,
        documents: documents
      ),
      Generators::LegacyAppeal.build(
        vbms_id: "115555555S",
        vacols_record: vacols_record,
        documents: documents,
        issues: []
      )
    ]
  end
  let!(:issues) { [Generators::Issue.build] }
  let! :attorney_user do
    User.authenticate!(roles: ["System Admin"])
  end

  let!(:vacols_tasks) { Fakes::QueueRepository.tasks_for_user(attorney_user.css_id) }
  let!(:vacols_appeals) { Fakes::QueueRepository.appeals_from_tasks(vacols_tasks) }

  context "loads queue table view" do
    scenario "table renders row per task" do
      visit "/queue"

      expect(page).to have_content(COPY::ATTORNEY_QUEUE_TABLE_TITLE)
      expect(find("tbody").find_all("tr").length).to eq(vacols_tasks.length)

      vet_not_appellant = vacols_appeals.reject { |a| a.appellant_first_name.nil? }.first
      vna_appeal_row = find("tbody").find("#table-row-#{vet_not_appellant.vacols_id}")
      first_cell = vna_appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{vet_not_appellant.veteran_full_name} (#{vet_not_appellant.vbms_id})")
      expect(first_cell).to have_content(COPY::CASE_DIFF_VETERAN_AND_APPELLANT)

      paper_case = vacols_appeals.select { |a| a.file_type.eql? "Paper" }.first
      pc_appeal_row = find("tbody").find("#table-row-#{paper_case.vacols_id}")
      first_cell = pc_appeal_row.find_all("td").first

      expect(first_cell).to have_content("#{paper_case.veteran_full_name} (#{paper_case.vbms_id.delete('S')})")
      expect(first_cell).to have_content(COPY::IS_PAPER_CASE)
    end
  end
end
