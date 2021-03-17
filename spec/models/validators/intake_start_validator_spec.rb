# frozen_string_literal: true

describe IntakeStartValidator, :all_dbs do
  let!(:user) { create(:user, station_id: "283") }
  let(:veteran) { create(:veteran) }
  # IntakeStartValidator expects an uncommitted intake (hence new)
  let(:intake) { HigherLevelReviewIntake.new(veteran_file_number: veteran.file_number, user: user) }

  context "#validate" do
    let(:validator) { described_class.new(intake: intake) }
    before { allow_any_instance_of(Fakes::BGSService).to receive(:station_conflict?) { station_conflict } }

    subject { validator.validate }

    context "when BGS does not show station conflict and allows modification" do
      let(:station_conflict) { false }

      it { is_expected.to be_truthy }
    end

    context "when BGS shows a station conflict" do
      let(:station_conflict) { true }

      it "sets error_code \"veteran_not_modifiable\" when BGS shows a station conflict", :aggregate_failures do
        subject

        # Github issue #15865, PR #16007
        # This test has been flaky and multiple folks have tried to address.
        # These expects are designed to give more info if this test continues
        # to flake.
        expect(intake.user).not_to eq(User.api_user)
        # Likely overkill, see conversation in PR for the why this is worthwhile
        expect(intake.user.id == User.api_user.id).to be_falsey
        expect(intake.is_a?(AppealIntake)).to be_falsey
        expect(validator.send(:user_bypasses_same_station_check?)).to be_falsey

        expect(intake.error_code).to eq "veteran_not_modifiable"
      end

      context "for an Appeal" do
        let(:intake) { AppealIntake.new(veteran_file_number: veteran.file_number, user: user) }

        context "intake user is on the BVA Intake team" do
          before { BvaIntake.singleton.add_user(user) }

          it "sets a veteran_not_modifiable error code" do
            subject

            expect(intake.error_code).to eq "veteran_not_modifiable"
          end

          context "user is also at station 101" do
            let(:user) { create(:user, station_id: User::BOARD_STATION_ID) }

            it { is_expected.to be_truthy }
          end
        end

        context "intake user is only at Station 101 but not a BvaIntake user" do
          let(:user) { create(:user, station_id: User::BOARD_STATION_ID) }

          it "sets a veteran_not_modifiable error code" do
            subject

            expect(intake.error_code).to eq "veteran_not_modifiable"
          end
        end
      end
    end

    context "user is api_user" do
      let(:user) { User.api_user }

      it { is_expected.to be_truthy }
    end
  end
end
