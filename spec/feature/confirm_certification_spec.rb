require "rails_helper"

RSpec.feature "Confirm Certification" do
  let!(:current_user) { User.authenticate! }

  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    Form8.pdf_service = FakePdfService

    # Put the Certification in the state to be confirmed
    certification = Certification.create!(vacols_id: appeal.vacols_id)
    form8 = Form8.create!(certification_id: certification.id)
    form8.assign_attributes_from_appeal(certification.appeal)
    form8.save
    certification.form8.save_pdf!
  end

  let(:nod) { Generators::Document.build(type: "NOD") }
  let(:soc) { Generators::Document.build(type: "SOC", received_at: Date.new(1987, 9, 6)) }
  let(:form9) { Generators::Document.build(type: "Form 9") }
  let(:vacols_record) do
    {
      template: :ready_to_certify,
      nod_date: nod.received_at,
      soc_date: soc.received_at,
      form9_date: form9.received_at
    }
  end

  let(:appeal) do
    Generators::Appeal.build(vacols_record: vacols_record, documents: [nod, soc, form9])
  end

  scenario "Screen reader user visits pdf link" do
    visit "certifications/#{appeal.vacols_id}"

    # We want this content to only appear for screen reader users, so
    # it will not be visible, but it **should** be in the DOM.
    expect(page).to have_text(:all, "The PDF viewer in your browser may not be accessible.")
    expect(page).to have_css(".usa-sr-only", visible: false)

    # Sending click or keypress events to elements that are not in the DOM doesn't seem to work,
    # so let's find the hidden link's href and visit it manually to check that the pdf can be
    # found there.
    pdf_href = page.find("#sr-download-link", visible: false)[:href]
    expect(pdf_href).to include("/#{appeal.vacols_id}/pdf")
  end

  scenario "Successful confirmation" do
    visit "certifications/#{appeal.vacols_id}"
    expect(page).to have_content("Review Form 8")
    click_on "Upload and certify"

    expect(Fakes::AppealRepository.certified_appeal).to_not be_nil
    expect(Fakes::AppealRepository.certified_appeal.vacols_id).to eq(appeal.vacols_id)
    expect(Fakes::AppealRepository.uploaded_form8.vacols_id).to eq(appeal.vacols_id)
    expect(Fakes::AppealRepository.uploaded_form8_appeal.vacols_id).to eq(appeal.vacols_id)

    expect(page).to have_content("Congratulations!")

    certification = Certification.find_or_create_by_vacols_id(appeal.vacols_id)
    expect(certification.reload.completed_at).to eq(Time.zone.now)
  end
end
