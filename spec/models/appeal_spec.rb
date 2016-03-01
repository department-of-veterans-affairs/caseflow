describe Appeal do
  context "#documents_match?" do
    let(:nod_document) { Document.new(type: :nod, received_at: 3.days.ago) }
    let(:soc_document) { Document.new(type: :soc, received_at: 2.days.ago) }
    let(:form9_document) { Document.new(type: :form9, received_at: 1.day.ago) }

    let(:appeal) do
      Appeal.new(
        nod_date: 3.days.ago,
        soc_date: 2.days.ago,
        form9_date: 1.day.ago,
        documents: [nod_document, soc_document, form9_document]
      )
    end

    subject { appeal.documents_match? }

    context "when there is an nod, soc, and form9 document matching the respective dates" do
      it { is_expected.to be_truthy }

      context "and ssoc dates match" do
        before do
          appeal.documents += [
            Document.new(type: :ssoc, received_at: 6.days.ago),
            Document.new(type: :ssoc, received_at: 7.days.ago),
            Document.new(type: :ssoc, received_at: 9.days.ago)
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
          Document.new(type: :ssoc, received_at: 6.days.ago),
          Document.new(type: :ssoc, received_at: 7.days.ago)
        ]

        appeal.ssoc_dates = [6.days.ago, 9.days.ago]
      end

      it { is_expected.to be_falsy }
    end
  end

  context ".find" do
    class FakeRepo
      def self.find(_id)
        Appeal.new(vso_name: "Shane's VSO")
      end
    end

    before { Appeal.repository = FakeRepo }
    subject { Appeal.find("123C") }

    it "delegates to the repository" do
      expect(subject.vso_name).to eq("Shane's VSO")
    end

    it "sets the vacols_id" do
      expect(subject.vacols_id).to eq("123C")
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
end
