# frozen_string_literal: true

describe VirtualHearing do
  context "validation tests" do
    let(:virtual_hearing) { build(:virtual_hearing) }

    subject { virtual_hearing.valid? }

    context "for a central ama hearing" do
      let(:virtual_hearing) do
        build(
          :virtual_hearing,
          hearing: build(
            :hearing,
            hearing_day: build(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
          )
        )
      end

      it { expect(subject).to be(true) }
    end

    context "for a central legacy hearing" do
      let(:virtual_hearing) do
        build(
          :virtual_hearing,
          hearing: build(
            :legacy_hearing,
            hearing_day: create(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
          )
        )
      end

      it { expect(subject).to be(true) }
    end
  end
end
