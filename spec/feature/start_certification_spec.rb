require "rails_helper"

class FakeAppealRepository
  class << self
    attr_writer :records
  end

  def self.find(id)
    @records[id]
  end
end
Appeal.repository = FakeAppealRepository

RSpec.feature "Start Certification" do
  let(:nod_document) { Document.new(type: :nod, received_at: 3.days.ago) }
  let(:soc_document) { Document.new(type: :soc, received_at: 2.days.ago) }
  let(:form9_document) { Document.new(type: :form9, received_at: 1.day.ago) }

  let(:appeal_ready_to_certify) do
    Appeal.new(
      nod_date: 3.days.ago,
      soc_date: 2.days.ago,
      form9_date: 1.day.ago,
      documents: [nod_document, soc_document, form9_document]
    )
  end

  let(:appeal_not_ready) { Appeal.new(nod_date: 1.day.ago) }

  scenario "Starting a certification with missing documents" do
    FakeAppealRepository.records = {
      "1234C" => appeal_not_ready
    }

    visit "certifications/new/1234C"
    expect(page).to have_content "Missing documents"
  end

  scenario "Starting a certifications with all documents matching" do
    FakeAppealRepository.records = {
      "1234C" => appeal_ready_to_certify
    }

    visit "certifications/new/1234C"
    expect(page).to have_content "Gotem"
  end
end
