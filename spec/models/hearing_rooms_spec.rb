# frozen_string_literal: true

describe HearingRooms do
  let(:hearing_room) { described_class.find!(hearing_room_key) }
  let(:hearing_room_key) { nil }

  context ".find!" do
    subject { hearing_room }

    context "hearing room is nil" do
      it { expect(subject).to be_nil }
    end

    Constants::HEARING_ROOMS_LIST.each do |key, value|
      context "for key (#{key})" do
        let(:hearing_room_key) { key.to_s }

        it "resolves to room with label '#{value['label']}'" do
          expect(subject).not_to be_nil
          expect(subject.label).to be(value["label"])
        end
      end
    end
  end
end
