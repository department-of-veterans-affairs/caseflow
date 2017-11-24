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
      let(:disposition) { "Withdrawn" }

      it "sets type" do
        subject
        expect(appeal_event.type).to eq(:withdrawn)
      end
    end

    context "when disposition is not mapped to an event type" do
      let(:disposition) { "Not a disposition" }

      it "sets type to other" do
        subject
        expect(appeal_event.type).to eq(:other_close)
      end
    end
  end

  context "issue_disposition=" do
    subject { appeal_event.issue_disposition = disposition }

    context "when disposition is a field grant" do
      let(:disposition) { "Advance Allowed in Field" }

      it "sets type" do
        subject
        expect(appeal_event.type).to eq(:field_grant)
      end
    end

    context "when disposition is any other event type" do
      let(:disposition) { "Allowed" }

      it "sets type to falsey" do
        subject
        expect(appeal_event.type).to be_falsey
      end
    end
  end

  context "hearing=" do
    subject { appeal_event.hearing = hearing }

    context "when disposition is supported" do
      let(:hearing) { Hearing.new(date: 4.days.ago, disposition: :no_show) }

      it "sets type and date based off of hearing" do
        subject

        expect(appeal_event.date).to eq(4.days.ago)
        expect(appeal_event.type).to eq(:hearing_no_show)
      end
    end

    context "when disposition is not supported" do
      let(:hearing) { Hearing.new(date: 4.days.ago, disposition: :postponed) }

      it "sets type to falsey" do
        subject

        expect(appeal_event.type).to be_falsey
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

  context "==" do
    it "is equal to an object with the same type and date" do
      a = AppealEvent.new(type: :nod, date: Time.zone.today)
      b = AppealEvent.new(type: :nod, date: Time.zone.today)
      expect(a).to eq(b)
    end
  end

  context "::EVENT_TYPE_FOR_DISPOSITIONS" do
    let(:vacols_dispositions) { VACOLS::Case::DISPOSITIONS.values }
    let(:event_dispositions) { AppealEvent::EVENT_TYPE_FOR_DISPOSITIONS.values.flatten }

    it "accounts for all VACOLS dispositions" do
      expect(vacols_dispositions - event_dispositions).to eq([])
    end
  end
end
