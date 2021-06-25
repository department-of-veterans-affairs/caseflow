# frozen_string_literal: true

describe Claimant, :postgres do
  let(:name) { nil }
  let(:relationship_to_veteran) { nil }
  let(:payee_code) { nil }
  let(:claimant_info) do
    { relationship: relationship_to_veteran, payee_code: payee_code }
  end

  let(:name_info) do
    {
      first_name: first_name,
      last_name: last_name
    }
  end

  let(:address_line_1) { nil }
  let(:address_line_2) { nil }
  let(:address_line_3) { nil }
  let(:city) { nil }
  let(:state) { nil }
  let(:zip_code) { nil }
  let(:country) { nil }
  let(:claimant_address) do
    {
      address_line_1: address_line_1,
      address_line_2: address_line_2,
      address_line_3: address_line_3,
      city: city,
      country: country,
      state: state,
      zip: zip_code
    }
  end

  context "lazy loading instance attributes from BGS" do
    let(:claimant) { create(:claimant, type: "DependentClaimant") }

    context "when claimant exists in BGS" do
      let(:first_name) { "HARRY" }
      let(:last_name) { "POTTER" }
      let(:relationship_to_veteran) { "SON" }
      let(:payee_code) { "12" }
      let(:address_line_1) { "4 Privet Dr" }
      let(:address_line_2) { "Little Whinging" }
      let(:city) { "Washington" }
      let(:state) { "DC" }
      let(:zip_code) { "20001" }
      let(:country) { "USA" }

      before do
        allow_any_instance_of(Fakes::BGSService).to(
          receive(:find_address_by_participant_id).and_return(claimant_address)
        )

        allow_any_instance_of(Fakes::BGSService).to(
          receive(:fetch_claimant_info_by_participant_id).and_return(claimant_info)
        )

        allow_any_instance_of(Fakes::BGSService).to(
          receive(:fetch_person_info).and_return(name_info)
        )
      end

      it "returns BGS attributes when accessed through instance" do
        expect(claimant.name).to eq "Harry Potter"
        expect(claimant.relationship).to eq relationship_to_veteran
        expect(claimant.bgs_payee_code).to eq payee_code
        expect(claimant.address_line_1).to eq address_line_1
        expect(claimant.address_line_2).to eq address_line_2
        expect(claimant.city).to eq city
        expect(claimant.state).to eq state
        expect(claimant.zip).to eq zip_code
        expect(claimant.country).to eq country
      end
    end
  end

  context ".create_without_intake!" do
    let(:appeal) { create(:appeal) }
    let(:date_of_birth) { "Sun, 05 Sep 1943 00:00:00 -0500" }
    let(:participant_id) { "1234" }

    before do
      allow_any_instance_of(BGSService).to receive(:fetch_person_info).and_return(
        birth_date: date_of_birth,
        first_name: "Bob",
        last_name: "Vance"
      )
    end

    it "saves date of birth" do
      claimant = appeal.claimants.create_without_intake!(
        participant_id: participant_id,
        payee_code: "1",
        type: "VeteranClaimant"
      )
      expect(claimant.date_of_birth).to eq(date_of_birth.to_date)
      person = Person.find_by(participant_id: participant_id)
      expect(person).to_not eq nil
      expect(person.date_of_birth).to eq(date_of_birth.to_date)
    end
  end

  context "#advanced_on_docket?" do
    let(:appeal) { create(:appeal, receipt_date: 1.year.ago) }

    context "when claimant satisfies AOD age criteria" do
      let(:claimant) { create(:claimant, :advanced_on_docket_due_to_age, decision_review: appeal) }

      it "returns true" do
        expect(claimant.advanced_on_docket?(appeal)).to eq(true)
        expect(claimant.advanced_on_docket_based_on_age?).to eq(true)
      end
    end

    context "when claimant has motion granted" do
      let(:claimant) { create(:claimant, decision_review: appeal) }

      before do
        create(:advance_on_docket_motion, person_id: claimant.person.id, granted: true, appeal: appeal)
      end

      it "returns true" do
        expect(claimant.advanced_on_docket?(appeal)).to eq(true)
        expect(claimant.advanced_on_docket_based_on_age?).to eq(false)
        expect(claimant.advanced_on_docket_motion_granted?(appeal)).to eq(true)
      end
    end

    context "when claimant is younger than 75 years old and has no motion granted" do
      let(:claimant) { create(:claimant, decision_review: appeal) }

      it "returns false" do
        expect(claimant.advanced_on_docket?(appeal)).to eq(false)
        expect(claimant.advanced_on_docket_based_on_age?).to eq(false)
        expect(claimant.advanced_on_docket_motion_granted?(appeal)).to eq(false)
      end
    end

    context "when claimant satisfies AOD age criteria and has motion granted" do
      let(:claimant) { create(:claimant, :advanced_on_docket_due_to_age, decision_review: appeal) }

      before do
        create(:advance_on_docket_motion, person_id: claimant.person.id, granted: true, appeal: appeal)
      end

      it "returns true" do
        expect(claimant.advanced_on_docket?(appeal)).to eq(true)
        expect(claimant.advanced_on_docket_based_on_age?).to eq(true)
        expect(claimant.advanced_on_docket_motion_granted?(appeal)).to eq(true)
      end
    end

    context "when AttorneyClaimant satisfies AOD age criteria and has motion granted" do
      let(:claimant) do
        create(:claimant, :advanced_on_docket_due_to_age,
               decision_review: appeal, type: "AttorneyClaimant")
      end

      before do
        create(:advance_on_docket_motion, person_id: claimant.person.id, granted: true, appeal: appeal)
      end

      it "returns false" do
        expect(claimant.advanced_on_docket_based_on_age?).to eq(false)
        expect(claimant.advanced_on_docket_motion_granted?(appeal)).to eq(false)
        expect(claimant.advanced_on_docket?(appeal)).to eq(false)
      end
    end
  end

  context "#power_of_attorney" do
    let(:claimant) { create(:claimant) }

    subject { claimant.power_of_attorney }

    it "returns BgsPowerOfAttorney" do
      expect(subject).to be_a BgsPowerOfAttorney
    end

    context "when PID and file number do not match BGS" do
      let(:claimant) do
        create(:claimant,
               participant_id: "no-such-pid",
               decision_review: build(:appeal, veteran_file_number: "no-such-file-number"))
      end

      let!(:bgs_service) { BGSService.new }

      before do
        allow(BGSService).to receive(:new) { bgs_service }
        allow(bgs_service).to receive(:fetch_poa_by_file_number).and_call_original
        allow(bgs_service).to receive(:fetch_poas_by_participant_ids).and_call_original
      end

      it "returns nil" do
        expect(subject).to be_nil
        expect(claimant.representative_name).to be_nil
      end

      it "calls BGS only once" do
        # rely on cache marker to avoid multiple BGS calls
        10.times { subject }

        expect(bgs_service).to have_received(:fetch_poa_by_file_number).once
        expect(bgs_service).to have_received(:fetch_poas_by_participant_ids).once
      end
    end

    context "when claimant is AttorneyClaimant" do
      let(:claimant) { create(:claimant, :advanced_on_docket_due_to_age, type: "AttorneyClaimant") }

      before do
        create(:bgs_attorney, participant_id: claimant.participant_id, name: "JOHN SMITH")
      end

      it "returns name of AttorneyClaimant" do
        expect(claimant.name).to eq "JOHN SMITH"
      end

      it "does not return a power of attorney" do
        expect(subject).to be nil
      end
    end
  end

  context "#valid?" do
    context "participant_id" do
      let(:participant_id) { "1234" }

      let(:decision_review) do
        build(:higher_level_review,
              id: 1,
              benefit_type: "fiduciary",
              veteran_file_number: create(:veteran).file_number)
      end

      let(:payee_code) { "10" }

      let!(:claimant) do
        create(:claimant, decision_review: decision_review, participant_id: participant_id, payee_code: payee_code)
      end

      context "when created with the same participant_id and the same decision_review" do
        subject { build(:claimant, decision_review: decision_review, participant_id: participant_id) }

        it "requires uniqueness" do
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:participant_id]).to eq ["has already been taken"]
        end
      end

      context "when created with the same participant_id and different decision_review" do
        let(:decision_review2) do
          build(:appeal,
                id: 1,
                veteran_file_number: create(:veteran).file_number)
        end

        subject { build(:claimant, decision_review: decision_review2, participant_id: participant_id) }

        it "does not require uniqueness" do
          expect(subject).to be_valid
        end
      end
    end

    context "payee_code" do
      let(:decision_review) do
        build(:higher_level_review, benefit_type: benefit_type, veteran_file_number: create(:veteran).file_number)
      end

      subject { build(:claimant, decision_review: decision_review) }

      context "when decision_review.benefit_type is compensation" do
        let(:benefit_type) { "compensation" }

        it "requires non-blank value" do
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:payee_code]).to eq ["blank"]
        end
      end

      context "when decision_review.benefit_type is pension" do
        let(:benefit_type) { "pension" }

        it "requires non-blank value" do
          expect(subject).to_not be_valid
          expect(subject.errors.messages[:payee_code]).to eq ["blank"]
        end
      end

      context "when decision_review.benefit_type is fiduciary" do
        let(:benefit_type) { "fiduciary" }

        it "allows blank value" do
          expect(subject).to be_valid
          expect(subject.errors.messages[:payee_code]).to eq []
        end
      end

      context "when decision_review.benefit_type is fiduciary" do
        before { FeatureToggle.enable!(:establish_fiduciary_eps) }
        after { FeatureToggle.disable!(:establish_fiduciary_eps) }
        let(:benefit_type) { "fiduciary" }

        it "requires non-blank value" do
          expect(subject).not_to be_valid
          expect(subject.errors.messages[:payee_code]).to eq ["blank"]
        end
      end
    end
  end
end
