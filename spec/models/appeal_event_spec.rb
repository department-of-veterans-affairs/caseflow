describe AppealEvent do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:appeal_event) { AppealEvent.new(type: type, date: date) }
  let(:date) { Time.zone.today }
  let(:type) { :nod }

  context "disposition=" do
    subject { appeal_event.disposition = disposition }

    context "when disposition is mapped to an event type" do
      let(:disposition) { "Allowed" }

      it "sets type" do
        subject
        expect(appeal_event.type).to eq(:bva_final_decision)
      end
    end

    context "when disposition is not mapped to an event type" do
      let(:disposition) { "Not a disposition" }

      it "sets type to nil" do
        subject
        expect(appeal_event.type).to be_nil
      end
    end
  end

  context "valid?" do
    subject { appeal_event.valid? }

    it { is_expected.to be_truthy }

    context "when no type" do
      let(:type) { nil }
      it { is_expected.to be_falsey }
    end

    context "when no date" do
      let(:date) { nil }
      it { is_expected.to be_falsey }
    end
  end

  context "::DISPOSITIONS_BY_EVENT_TYPE" do
    let(:vacols_dispositions) { VACOLS::Case::DISPOSITIONS.values }
    let(:event_dispositions) { AppealEvent::DISPOSITIONS_BY_EVENT_TYPE.values.flatten }

    it "accounts for all VACOLS dispositions" do
      expect(vacols_dispositions - event_dispositions).to eq([])
    end
  end
end
