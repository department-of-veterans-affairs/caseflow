describe Appeal do
  context "#documents_match?" do
    let(:nod_document) { Document.new(type: "NOD", received_at: 3.days.ago) }
    let(:soc_document) { Document.new(type: "SOC", received_at: 2.days.ago) }
    let(:form9_document) { Document.new(type: nil, alt_types: ["Form 9"], received_at: 1.day.ago) }

    let(:appeal) do
      Appeal.new(
        nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        form9_date: 1.day.ago,
        documents: [nod_document, soc_document, form9_document]
      )
    end

    before do
      @old_repo = Appeal.repository
      Appeal.repository = Fakes::AppealRepository
      Fakes::AppealRepository.records = nil
    end
    after { Appeal.repository = @old_repo }

    subject { appeal.documents_match? }

    context "when there is an nod, soc, and form9 document matching the respective dates" do
      it { is_expected.to be_truthy }

      context "and ssoc dates match" do
        before do
          appeal.documents += [
            Document.new(type: "SSOC", received_at: 6.days.ago),
            Document.new(type: "SSOC", received_at: 7.days.ago),
            Document.new(type: "SSOC", received_at: 9.days.ago)
          ]
          appeal.ssoc_dates = [6.days.ago, 7.days.ago]
        end

        it { is_expected.to be_truthy }
      end
    end

    context "when the nod date is mismatched" do
      before { nod_document.received_at = 5.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when the soc date is mismatched" do
      before { soc_document.received_at = 5.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when the form9 date is mismatched" do
      before { form9_document.received_at = 5.days.ago }
      it { is_expected.to be_falsy }
    end

    context "when at least one ssoc doesn't match" do
      before do
        appeal.documents += [
          Document.new(type: "SSOC", received_at: 6.days.ago),
          Document.new(type: "SSOC", received_at: 7.days.ago)
        ]

        appeal.ssoc_dates = [6.days.ago, 9.days.ago]
      end

      it { is_expected.to be_falsy }
    end
  end

  context ".find_or_create_by_vacols_id" do
    before do
      Appeal.repository.stub(:load_vacols_data) do |_appeal|
        nil
      end
    end
    subject { Appeal.find_or_create_by_vacols_id("123C") }
    context "sets the vacols_id" do
      before do
        Appeal.any_instance.stub(:save) do |appeal|
          appeal
        end
      end

      it do
        is_expected.to be_an_instance_of(Appeal)
        expect(subject.vacols_id).to eq("123C")
      end
    end

    it "persists in database" do
      expect(Appeal.find_by(vacols_id: subject.vacols_id)).to be_an_instance_of(Appeal)
    end
  end

  context "#certified?" do
    subject { Appeal.new(certification_date: 2.days.ago) }

    it "reads certification date off the appeal" do
      expect(subject.certified?).to be_truthy
      subject.certification_date = nil
      expect(subject.certified?).to be_falsy
    end
  end

  context "#hearing_pending?" do
    subject { Appeal.new(hearing_requested: false, hearing_held: false) }

    it "determines whether an appeal is awaiting a hearing" do
      expect(subject.hearing_pending?).to be_falsy
      subject.hearing_requested = true
      expect(subject.hearing_pending?).to be_truthy
      subject.hearing_held = true
      expect(subject.hearing_pending?).to be_falsy
    end
  end

  context "#sanitized_vbms_id" do
    subject { Appeal.new(vbms_id: "123C") }

    it "left-pads case-number ids" do
      expect(subject.sanitized_vbms_id).to eq("00000123")
    end

    it "left-pads 7-digit case-number ids" do
      subject.vbms_id = "2923988C"
      expect(subject.sanitized_vbms_id).to eq("02923988")
    end

    it "doesn't left-pad social security ids" do
      subject.vbms_id = "123S"
      expect(subject.sanitized_vbms_id).to eq("123")
    end
  end

  context "#partial_grant?" do
    subject { appeal.partial_grant? }
    context "is false" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete", disposition: "Allowed") }
      it { is_expected.to be_falsey }
    end

    context "is true" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand", disposition: "Allowed") }
      it { is_expected.to be_truthy }
    end
  end

  context "#full_grant?" do
    subject { appeal.full_grant? }
    context "is false" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand") }
      it { is_expected.to be_falsey }
    end

    context "is true" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete") }
      it { is_expected.to be_truthy }
    end
  end

  context "#decision_type" do
    subject { appeal.decision_type }
    context "is a full grant" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Remand", disposition: "Allowed") }
      it { is_expected.to eq("Partial Grant") }
    end

    context "is a partial grant" do
      let(:appeal) { Appeal.new(vacols_id: "123", status: "Complete") }
      it { is_expected.to eq("Full Grant") }
    end
  end
end
