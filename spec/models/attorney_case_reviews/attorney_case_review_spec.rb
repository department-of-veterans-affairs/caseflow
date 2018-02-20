describe AttorneyCaseReview do
  context ".complete!" do
    subject { AttorneyCaseReview.complete!(params) }

    let(:judge) { User.create(css_id: "CFS123", station_id: Judge::JUDGE_STATION_ID) }
    let(:attorney) { User.create(css_id: "CFS456", station_id: "317") }

    context "when all parameters are present and Vacols update is successful" do
      before do
        allow(QueueRepository).to receive(:reassign_case_to_judge).and_return(true)
      end

      let(:params) do
        {
          type: "OMORequest",
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          vacols_id: "123456",
          attorney: attorney
        }
      end

      it "should create AttorneyCaseReview record" do
        expect(subject.class).to eq OMORequest
        expect(subject.valid?).to eq true
        expect(subject.work_product).to eq "OMO - IME"
        expect(subject.document_id).to eq "123456789.1234"
        expect(subject.note).to eq "something"
        expect(subject.reviewing_judge).to eq judge
        expect(subject.attorney).to eq attorney
      end
    end

    context "when not all required parameters are present and Vacols update is successful" do
      before do
        allow(QueueRepository).to receive(:reassign_case_to_judge).and_return(true)
      end

      let(:params) do
        {
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          vacols_id: "123456",
          attorney: attorney
        }
      end

      it "should not create AttorneyCaseReview record" do
        expect(subject).to eq nil
        expect(AttorneyCaseReview.count).to eq 0
      end
    end

    context "when all required parameters are present and Vacols update throws an error" do
      before do
        allow(QueueRepository).to receive(:reassign_case_to_judge).and_return(AttorneyCaseReview::EXCEPTIONS.sample)
      end

      let(:params) do
        {
          reviewing_judge: judge,
          work_product: "OMO - IME",
          document_id: "123456789.1234",
          overtime: true,
          note: "something",
          vacols_id: "123456",
          attorney: attorney
        }
      end

      it "should not create AttorneyCaseReview record" do
        expect(subject).to eq nil
        expect(AttorneyCaseReview.count).to eq 0
      end
    end
  end
end
