# frozen_string_literal: true

describe IntakeStartValidator, :postgres do
  context "#validate" do
    let(:user) { create(:user, station_id: "283") }

    let(:veteran) { create(:veteran) }

    let(:review) { HigherLevelReview.new }

    let(:intake) do
      # IntakeStartValidator expects an uncommitted intake (hence new)
      HigherLevelReviewIntake.new(veteran_file_number: veteran.file_number, detail: review, user: user)
    end

    let(:validator) do
      described_class.new(intake: intake)
    end

    let(:validate_error_code) do
      validator.validate
      intake.error_code
    end

    it "sets no error_code when BGS allows modification" do
      allow_any_instance_of(BGSService).to receive(:station_conflict?) { false }
      expect(validate_error_code).to be nil
    end

    it "sets error_code \"veteran_not_modifiable\" when BGS shows a station conflict" do
      allow_any_instance_of(BGSService).to receive(:station_conflict?) { true }
      expect(validate_error_code).to eq "veteran_not_modifiable"
    end

    context "intaking an Appeal with a same-station conflict" do
      before do
        allow_any_instance_of(BGSService).to receive(:station_conflict?) { true }
      end

      let(:intake) do
        AppealIntake.new(veteran_file_number: veteran.file_number, detail: review, user: user)
      end
      subject { validate_error_code }

      context "intake user is on the BVA Intake team" do
        it "sets a veteran_not_modifiable error code" do
          BvaIntake.singleton.add_user(user)
          is_expected.to eq "veteran_not_modifiable"
        end
      end

      context "intake user is at Station 101" do
        let(:user) { create(:user, station_id: User::BOARD_STATION_ID) }

        it "sets a veteran_not_modifiable error code" do
          is_expected.to eq "veteran_not_modifiable"
        end

        context "intake user at Station 101 is also on the BVA Intake team" do
          it "sets no error_code" do
            BvaIntake.singleton.add_user(user)
            is_expected.to be nil
          end
        end
      end
    end

    context "user is api_user" do
      let(:user) { User.api_user }

      it "sets no error_code when user is User.api_user" do
        expect(validate_error_code).to be nil
      end
    end
  end
end
