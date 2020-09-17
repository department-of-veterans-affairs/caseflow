# frozen_string_literal: true

describe HearingDayRoomAssignment do
  let(:service) do
    described_class.new(
      request_type: request_type,
      assign_room: assign_room,
      scheduled_for: scheduled_for,
      room: room
    )
  end
  let(:request_type) { nil }
  let(:assign_room) { true }
  let(:scheduled_for) { Time.zone.today }
  let(:room) { "1" }

  context ".available_room" do
    subject { service.available_room }

    context "for a central docket" do
      let(:request_type) { HearingDay::REQUEST_TYPES[:central] }

      context "no rooms are assigned" do
        it { expect(subject).to be("2") }
      end

      context "there is already a docket for room 2" do
        let!(:existing_hearing_day) do
          create(
            :hearing_day,
            scheduled_for: scheduled_for,
            request_type: request_type,
            room: "2"
          )
        end

        it { expect(subject).to be_nil }
      end
    end

    context "for a video docket" do
      let(:request_type) { HearingDay::REQUEST_TYPES[:video] }
      let(:regional_office) { "RO01" }

      context "no rooms are assigned" do
        it "returns non-nil room" do
          expect(subject).to_not be_nil
        end

        it "returns different rooms for each case" do
          first_pass = subject

          create(
            :hearing_day,
            request_type: request_type,
            room: first_pass,
            scheduled_for: scheduled_for,
            regional_office: regional_office
          )

          second_pass = described_class
            .new(
              request_type: request_type,
              assign_room: assign_room,
              scheduled_for: scheduled_for,
              room: nil
            )
            .available_room

          expect(first_pass).to_not be(second_pass)
        end
      end

      context "with a central docket already assigned to room 1" do
        let!(:central_docket) do
          create(
            :hearing_day,
            scheduled_for: scheduled_for,
            request_type: HearingDay::REQUEST_TYPES[:central],
            room: "1"
          )
        end

        it "assigns room 3" do
          expect(subject).to eq("3")
        end
      end
    end
  end
end
