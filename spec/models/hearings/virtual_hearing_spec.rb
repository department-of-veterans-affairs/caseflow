# frozen_string_literal: true

describe VirtualHearing do
  context "#guest_pin" do
    let(:virtual_hearing) do
      create(
        :virtual_hearing,
        hearing: create(
          :hearing,
          hearing_day: create(
            :hearing_day,
            regional_office: "RO42",
            request_type: HearingDay::REQUEST_TYPES[:video]
          )
        )
      )
    end
    let(:virtual_hearing_aliased) do
      create(
        :virtual_hearing,
        :initialized,
        hearing: create(
          :hearing,
          hearing_day: create(
            :hearing_day,
            regional_office: "RO42",
            request_type: HearingDay::REQUEST_TYPES[:video]
          )
        )
      )
    end

    it "returns the database column when override is nil" do
      # Set the DB columns to ensure they can still be accessed for older hearings
      virtual_hearing.update(guest_pin: rand(1000..9999).to_s[0..3].to_i)
      virtual_hearing.update(host_pin: rand(1000..9999).to_s[0..3].to_i)
      virtual_hearing.reload

      expect(virtual_hearing.guest_pin_long).to eq nil
      expect(virtual_hearing.guest_pin.to_s.length).to eq 4
      expect(virtual_hearing.host_pin_long).to eq nil
      expect(virtual_hearing.host_pin.to_s.length).to eq 4
    end

    it "returns the aliased pins when set" do
      expect(virtual_hearing_aliased[:guest_pin]).to eq nil
      expect(virtual_hearing_aliased.guest_pin.to_s.length).to eq 11
      expect(virtual_hearing_aliased[:host_pin]).to eq nil
      expect(virtual_hearing_aliased.host_pin.to_s.length).to eq 8
    end
  end

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

      it { expect(subject).to be(false) }
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

      it { expect(subject).to be(false) }
    end

    shared_examples_for "hearing with existing virtual hearing" do
      context "has existing active virtual hearing" do
        let!(:existing_virtual_hearing) do
          create(
            :virtual_hearing,
            :initialized,
            :all_emails_sent,
            status: :active,
            hearing: hearing
          )
        end
        let(:virtual_hearing) { build(:virtual_hearing, hearing: hearing) }

        it "is invalid" do
          hearing.reload
          expect(subject).to be(false)
        end
      end

      context "has existing cancelled virtual hearing" do
        let!(:existing_virtual_hearing) do
          create(
            :virtual_hearing,
            :initialized,
            :all_emails_sent,
            status: :cancelled,
            hearing: hearing
          )
        end
        let(:virtual_hearing) { build(:virtual_hearing, hearing: hearing) }

        it "is valid" do
          hearing.reload
          expect(subject).to be(true)
        end
      end
    end

    context "for a video ama hearing" do
      let(:hearing) do
        create(
          :hearing,
          hearing_day: create(
            :hearing_day,
            request_type: HearingDay::REQUEST_TYPES[:video],
            regional_office: "RO01"
          )
        )
      end

      it_behaves_like "hearing with existing virtual hearing"
    end

    context "for video legacy hearing" do
      let(:hearing) do
        create(
          :legacy_hearing,
          hearing_day: create(
            :hearing_day,
            request_type: HearingDay::REQUEST_TYPES[:video],
            regional_office: "RO01"
          )
        )
      end

      it_behaves_like "hearing with existing virtual hearing"
    end
  end
end
