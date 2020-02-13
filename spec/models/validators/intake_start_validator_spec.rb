# frozen_string_literal: true

describe IntakeStartValidator, :postgres do
  context "#validate" do
    let(:user) { create(:user) }

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

    context "intaking an Appeal" do
      let(:intake) do
        AppealIntake.new(veteran_file_number: veteran.file_number, detail: review, user: user)
      end
      subject { validate_error_code }

      it "sets an error_code if BGS shows a station conflict" do
        allow_any_instance_of(BGSService).to receive(:station_conflict?) { true }
        is_expected.to eq "veteran_not_modifiable"
      end

      context "user is on the MailTeam at Station 101" do
        let(:user) do
          user = create(:user, station_id: User::BOARD_STATION_ID)
          MailTeam.singleton.add_user(user)
          user
        end

        it "sets no error_code even if BGS shows a station conflict" do
          allow_any_instance_of(BGSService).to receive(:station_conflict?) { true }
          is_expected.to be nil
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
