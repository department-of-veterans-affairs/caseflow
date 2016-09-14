describe Certification do
  let(:certification_date) { nil }
  let(:certification) { Certification.new(vacols_id: "4949") }
  let(:appeal) { Appeal.new(vacols_id: "4949", vbms_id: "VB12", certification_date: certification_date) }

  before do
    Timecop.freeze
    Fakes::AppealRepository.records = { "4949" => appeal }
  end

  after { Timecop.return }

  context "#start!" do
    subject { certification.start! }

    context "when appeal has already been certified" do
      let(:appeal) { Fakes::AppealRepository.appeal_already_certified }

      it "returns already_certified and sets the flag" do
        expect(subject).to eq(:already_certified)
        expect(certification.reload.already_certified).to be_truthy
        expect(certification.form8_started_at).to be_nil
      end
    end

    context "when appeal is missing certification data" do
      it "returns already_certified and sets the flag" do
        expect(subject).to eq(:data_missing)
        expect(certification.reload.vacols_data_missing).to be_truthy
        expect(certification.form8_started_at).to be_nil
      end
    end

    context "when a document is mismatched" do
      let(:appeal) { Fakes::AppealRepository.appeal_mismatched_nod }

      it "returns mismatched_documents and sets the flag" do
        expect(subject).to eq(:mismatched_documents)

        expect(certification.reload.nod_matching_at).to be_nil
        expect(certification.soc_matching_at).to eq(Time.zone.now)
        expect(certification.form9_matching_at).to eq(Time.zone.now)
        expect(certification.ssocs_required).to be_falsey
        expect(certification.ssocs_matching_at).to be_nil
        expect(certification.form8_started_at).to be_nil
      end
    end

    context "when appeal is ready to start" do
      let(:appeal) { Fakes::AppealRepository.appeal_ready_to_certify }

      it "returns success and sets timestamps" do
        expect(subject).to eq(:started)

        expect(certification.reload.nod_matching_at).to eq(Time.zone.now)
        expect(certification.soc_matching_at).to eq(Time.zone.now)
        expect(certification.form9_matching_at).to eq(Time.zone.now)
        expect(certification.ssocs_required).to be_falsey
        expect(certification.ssocs_matching_at).to be_nil
        expect(certification.form8_started_at).to eq(Time.zone.now)
      end

      context "when appeal has ssoc" do
        before do
          appeal.ssoc_dates = [10.days.ago]
          appeal.documents << Document.new(type: :ssoc, received_at: 10.days.ago)
        end

        it "returns success and sets ssoc_required" do
          expect(subject).to eq(:started)
          expect(certification.ssocs_required).to be_truthy
          expect(certification.ssocs_matching_at).to eq(Time.zone.now)
        end
      end
    end
  end

  context "#form8" do
    subject { certification.form8("TEST_form8") }

    context "when a form8 exists in the cache for the passed key" do
      before do
        Rails.cache.write("TEST_form8", Form8.new(vacols_id: "4949", file_number: "SAVED88").attributes)
      end

      it "returns the cached form8" do
        expect(subject.file_number).to eq("SAVED88")
      end
    end

    context "when no cached form8 exists" do
      before do
        Rails.cache.write("TEST_form8", nil)
      end

      it "returns a new form8" do
        expect(subject.file_number).to eq("VB12")
      end
    end
  end

  context "#appeal" do
    subject { certification.appeal }

    it "lazily loads the appeal for the certification" do
      expect(subject.vbms_id).to eq(appeal.vbms_id)
    end
  end

  context ".from_vacols_id!" do
    let(:vacols_id) { "1122" }
    subject { Certification.from_vacols_id!(vacols_id) }

    context "when certification exists with that vacols_id" do
      before { @certification = Certification.create(vacols_id: vacols_id) }

      it "loads that certification" do
        expect(subject.id).to eq(@certification.id)
      end
    end

    context "when certification doesn't exist with that vacols_id" do
      it "creates a certification" do
        expect(subject.id).to eq(Certification.where(vacols_id: vacols_id).first.id)
      end
    end
  end
end
