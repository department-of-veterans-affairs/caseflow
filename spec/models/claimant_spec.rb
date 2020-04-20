# frozen_string_literal: true

describe Claimant, :postgres do
  let(:name) { nil }
  let(:relationship_to_veteran) { nil }
  let(:claimant_info) do
    {
      relationship: relationship_to_veteran
    }
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
    let(:claimant) { create(:claimant) }

    context "when claimant exists in BGS" do
      let(:first_name) { "HARRY" }
      let(:last_name) { "POTTER" }
      let(:relationship_to_veteran) { "SON" }
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
      claimant = appeal.claimants.create_without_intake!(participant_id: participant_id, payee_code: "1")
      expect(claimant.date_of_birth).to eq(date_of_birth.to_date)
      person = Person.find_by(participant_id: participant_id)
      expect(person).to_not eq nil
      expect(person.date_of_birth).to eq(date_of_birth.to_date)
    end
  end

  context "#advanced_on_docket?" do
    context "when claimant is over 75 years old" do
      it "returns true" do
        claimant = create(:claimant, :advanced_on_docket_due_to_age)
        expect(claimant.advanced_on_docket?(1.year.ago)).to eq(true)
      end
    end

    context "when claimant has motion granted" do
      it "returns true" do
        claimant = create(:claimant)
        create(:advance_on_docket_motion, person_id: claimant.person.id, granted: true)

        expect(claimant.advanced_on_docket?(1.year.ago)).to eq(true)
      end
    end

    context "when claimant is younger than 75 years old and has no motion granted" do
      it "returns false" do
        claimant = create(:claimant)
        expect(claimant.advanced_on_docket?(1.year.ago)).to eq(false)
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

      let!(:claimant) do
        create(:claimant, decision_review: decision_review, participant_id: participant_id)
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
    end
  end
end
