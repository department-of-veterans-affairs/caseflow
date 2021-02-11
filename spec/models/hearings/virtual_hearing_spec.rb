# frozen_string_literal: true

describe VirtualHearing do
  shared_examples "all test link behaviors" do
    it "returns representative link when title is 'Representative'" do
      recipient = "Representative"
      expect(virtual_hearing.test_link(recipient)).to eq link(recipient)
    end

    it "returns appellant link when appellant is not the veteran" do
      recipient = "Appellant"
      virtual_hearing.hearing.appeal.update(veteran_is_not_claimant: true)
      expect(virtual_hearing.test_link("Veteran")).to eq link(recipient)
    end

    it "returns veteran link when appellant is the veteran" do
      recipient = "Veteran"
      expect(virtual_hearing.test_link(recipient)).to eq link(recipient)
    end

    it "returns veteran link when title is not rep and appellant is the veteran" do
      recipient = "Something"
      expect(virtual_hearing.test_link(recipient)).to eq link("Veteran")
    end
  end

  shared_context "virtual hearing created with new link generation" do
    let(:virtual_hearing) do
      build(
        :virtual_hearing,
        :link_generation_initialized,
        hearing: build(
          :hearing,
          hearing_day: build(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
        )
      )
    end
  end

  shared_context "virtual hearing not created with new link generation" do
    let(:virtual_hearing) do
      build(
        :virtual_hearing,
        :initialized,
        hearing: build(
          :hearing,
          hearing_day: build(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
        )
      )
    end
  end

  context "#test_link" do
    context "vh created with new link generation" do
      def link(name)
        "https://vc.va.gov/bva-app?conference=test_call&name=#{name}&join=1"
      end

      include_context "virtual hearing created with new link generation"
      include_examples "all test link behaviors"
    end

    context "vh not created with new link generation" do
      def link(name)
        "https://care.va.gov/webapp2/conference/test_call?name=#{name}&join=1"
      end

      include_context "virtual hearing not created with new link generation"
      include_examples "all test link behaviors"
    end
  end

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

  context "#status" do
    shared_examples "returns correct status" do |status|
      it "returns correct status" do
        expect(subject).to eq(status)
      end
    end
    subject { virtual_hearing.status }

    context "cancelled" do
      let(:virtual_hearing) do
        build(
          :virtual_hearing,
          :initialized,
          hearing: build(
            :hearing,
            hearing_day: build(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
          ),
          request_cancelled: true
        )
      end

      include_examples "returns correct status", :cancelled
    end

    context "closed" do
      let(:virtual_hearing) do
        build(
          :virtual_hearing,
          :initialized,
          hearing: build(
            :hearing,
            hearing_day: build(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
          ),
          conference_deleted: true
        )
      end

      include_examples "returns correct status", :closed
    end

    context "active" do
      context "vh created with new link generation" do
        include_context "virtual hearing created with new link generation"
        include_examples "returns correct status", :active
      end

      context "vh not created with new link generation" do
        include_context "virtual hearing not created with new link generation"
        include_examples "returns correct status", :active
      end
    end

    context "pending" do
      let(:virtual_hearing) do
        build(
          :virtual_hearing,
          hearing: build(
            :hearing,
            hearing_day: build(:hearing_day, request_type: HearingDay::REQUEST_TYPES[:central])
          )
        )
      end

      include_examples "returns correct status", :pending
    end
  end
end
