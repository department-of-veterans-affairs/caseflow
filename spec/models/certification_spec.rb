describe Certification do
  let(:certification_date) { nil }
  let(:certification) { Certification.new(vacols_id: "4949") }
  let(:appeal_hash) { { vacols_id: "4949", vbms_id: "VB12", certification_date: certification_date } }
  let(:appeal) do
    Appeal.new(appeal_hash)
  end

  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
    Fakes::AppealRepository.records = { "4949" => appeal_hash }
    Certification.delete_all
    Task.delete_all
    Appeal.delete_all
    Appeal.stub(:find_or_create_by_vacols_id) do |_vacols_id|
      appeal
    end
    Appeal.repository.stub(:load_vacols_data) {}
  end

  after do
    Timecop.return
    Fakes::AppealRepository.documents = nil
  end

  context "#appeal" do
    subject { certification.appeal }
    before do
      Fakes::AppealRepository.set_vbms_documents!
    end

    it "includes documents" do
      expect(subject.documents).to_not be_empty

      expect_any_instance_of(Appeal).to_not receive(:fetch_documents!).at_least(1).times
      # test it doesn't fetch documents a 2nd time
      subject
    end
  end

  context "#start!" do
    subject { certification.start! }

    context "when appeal has already been certified" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_already_certified }

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
      let(:appeal_hash) { Fakes::AppealRepository.appeal_mismatched_nod }

      it "returns mismatched_documents and sets the flag" do
        expect(subject).to eq(:mismatched_documents)

        expect(certification.reload.nod_matching_at).to be_nil
        expect(certification.soc_matching_at).to eq(Time.zone.now)
        expect(certification.form9_matching_at).to eq(Time.zone.now)
        expect(certification.ssocs_required).to be_falsey
        expect(certification.ssocs_matching_at).to be_nil
        expect(certification.form8_started_at).to be_nil
      end

      it "is included in the relevant stats" do
        subject

        expect(Certification.was_missing_doc.count).to eq(1)
        expect(Certification.was_missing_nod.count).to eq(1)
        expect(Certification.was_missing_soc.count).to eq(0)
        expect(Certification.was_missing_ssoc.count).to eq(0)
        expect(Certification.was_missing_form9.count).to eq(0)
      end
    end

    context "when ssocs are mismatched" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_mismatched_ssoc }

      it "is included in the relevant stats" do
        subject

        expect(Certification.was_missing_doc.count).to eq(1)
        expect(Certification.was_missing_nod.count).to eq(0)
        expect(Certification.was_missing_soc.count).to eq(0)
        expect(Certification.was_missing_ssoc.count).to eq(1)
        expect(Certification.was_missing_form9.count).to eq(0)
      end
    end

    context "when multiple docs are mismatched" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_mismatched_docs }

      it "is included in the relevant stats" do
        subject

        expect(Certification.was_missing_doc.count).to eq(1)
        expect(Certification.was_missing_nod.count).to eq(1)
        expect(Certification.was_missing_soc.count).to eq(1)
        expect(Certification.was_missing_ssoc.count).to eq(1)
        expect(Certification.was_missing_form9.count).to eq(1)
      end
    end

    context "when appeal is ready to start" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_ready_to_certify }

      it "returns success and sets timestamps" do
        expect(subject).to eq(:started)

        expect(certification.reload.nod_matching_at).to eq(Time.zone.now)
        expect(certification.soc_matching_at).to eq(Time.zone.now)
        expect(certification.form9_matching_at).to eq(Time.zone.now)
        expect(certification.ssocs_required).to be_falsey
        expect(certification.ssocs_matching_at).to be_nil
        expect(certification.form8_started_at).to eq(Time.zone.now)
      end

      it "no ssoc does not trip missing ssoc stat" do
        subject

        expect(Certification.was_missing_ssoc.count).to eq(0)
      end

      context "when appeal has ssoc" do
        before do
          appeal.ssoc_dates = [10.days.ago]
          appeal.documents << Document.new(type: "SSOC", received_at: 10.days.ago)
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

  context "#time_to_certify" do
    subject { certification.time_to_certify }

    before do
      certification.start!
    end

    context "when appeal has already been certified" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_already_certified }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when appeal has yet to be certified" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_ready_to_certify }

      it "returns nil" do
        expect(subject).to be_nil
      end
    end

    context "when appeal has been certified using Caseflow" do
      let(:appeal_hash) { Fakes::AppealRepository.appeal_ready_to_certify }

      before do
        Timecop.freeze(Time.utc(2015, 1, 1, 13, 0, 0))
        certification.complete!
      end

      it "returns the time since certification started" do
        expect(subject).to eq(1.hour)
      end
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
