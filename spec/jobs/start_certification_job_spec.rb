require "rails_helper"

describe StartCertificationJob do
  let(:certification_date) { nil }
  let(:nod) { Generators::Document.build(type: "NOD") }
  let(:soc) { Generators::Document.build(type: "SOC", received_at: Date.new(1987, 9, 6)) }
  let(:form9) { Generators::Document.build(type: "Form 9") }
  let(:documents) { [nod, soc, form9] }

  let(:vacols_record_template) { :ready_to_certify }
  let(:ssoc_date) { nil }
  let(:vacols_record) do
    {
      template: vacols_record_template,
      nod_date: nod.received_at,
      soc_date: soc.received_at,
      ssoc_dates: ssoc_date ? [ssoc_date] : nil,
      form9_date: form9.received_at
    }
  end
  let(:appeal) do
    Generators::Appeal.build(vacols_record: vacols_record, documents: documents)
  end

  context ".perform" do
    it "indicates when starting certification is successful" do
      certification = Certification.new(
        vacols_id: appeal.vacols_id,
        loading_data: true
      )
      StartCertificationJob.perform_now(certification)

      expect(certification.loading_data).to eq(false)
      expect(certification.loading_data_failed).to eq(false)
    end

    it "indicates when starting certification failed" do
      certification = Certification.new(
        vacols_id: "FAKE_ID_WITH_NO_DATA",
        loading_data: true
      )
      StartCertificationJob.perform_now(certification)

      expect(certification.loading_data_failed).to eq(true)
    end
  end
end
