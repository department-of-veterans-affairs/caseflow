# frozen_string_literal: true

describe Intake, :postgres do
  before do
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))

    RequestStore[:current_user] = user
  end

  class TestIntake < Intake
    def find_or_build_initial_detail
      # Just putting any ole database object here for testing
      @find_or_build_initial_detail ||= Generators::User.build
    end
  end

  class AnotherTestIntake < Intake; end

  let(:veteran_file_number) { "64205050" }
  let(:country) { "USA" }

  let(:detail) do
    build(:ramp_election, veteran_file_number: veteran_file_number, notice_date: Time.zone.now)
  end

  let(:user) { Generators::User.build }
  let(:another_user) { Generators::User.build(full_name: "David Schwimmer") }

  let(:intake) do
    TestIntake.new(
      veteran_file_number: veteran_file_number,
      detail: detail,
      user: user,
      started_at: 15.minutes.ago,
      completion_status: completion_status,
      completion_started_at: completion_started_at
    )
  end

  let(:ramp_election_intake) do
    RampElectionIntake.new(
      veteran_file_number: veteran_file_number,
      detail: detail,
      user: user,
      started_at: 15.minutes.ago,
      completion_status: completion_status,
      completion_started_at: completion_started_at
    )
  end

  let(:ramp_refiling_intake) do
    RampRefilingIntake.new(
      veteran_file_number: veteran_file_number,
      detail: detail,
      user: user,
      started_at: 15.minutes.ago,
      completion_status: completion_status,
      completion_started_at: completion_started_at
    )
  end

  let!(:veteran) { Generators::Veteran.build(file_number: "64205050", country: country) }

  let(:completion_status) { nil }
  let(:completion_started_at) { nil }

  context ".build" do
    subject { Intake.build(form_type: form_type, veteran_file_number: veteran_file_number, user: user) }

    context "when form_type is supported" do
      let(:form_type) { "ramp_election" }

      it "creates expected", :aggregate_failures do
        is_expected.to be_a(RampElectionIntake)
        is_expected.to have_attributes(veteran_file_number: veteran_file_number, user: user)
      end
    end

    context "when form_type is not supported" do
      let(:form_type) { "not_a_real_form" }

      it "raises error" do
        expect { subject }.to raise_error(Intake::FormTypeNotSupported)
      end
    end
  end

  context ".in_progress" do
    subject { Intake.in_progress }

    let!(:started_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 15.minutes.ago
      )
    end

    let!(:expired_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: another_user,
        started_at: 25.hours.ago
      )
    end

    let!(:completed_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: "success"
      )
    end

    it "returns in progress intakes" do
      expect(subject).to include(started_intake)
      expect(subject).to_not include(expired_intake)
      expect(subject).to_not include(completed_intake)
    end
  end

  context ".expired" do
    subject { Intake.expired }

    let!(:started_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 15.minutes.ago
      )
    end

    let!(:expired_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: another_user,
        started_at: 25.hours.ago
      )
    end

    let!(:completed_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: "success"
      )
    end

    it "returns expired intakes" do
      expect(subject).to_not include(started_intake)
      expect(subject).to include(expired_intake)
      expect(subject).to_not include(completed_intake)
    end
  end

  context ".flagged_for_manager_review" do
    subject { Intake.flagged_for_manager_review }

    let!(:completed_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago
      )
    end

    let!(:canceled_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: :canceled,
        cancel_reason: :duplicate_ep
      )
    end

    let!(:intake_not_accessible) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: :error,
        error_code: :veteran_not_accessible
      )
    end

    let!(:intake_not_valid) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: :error,
        error_code: :veteran_not_valid
      )
    end

    let!(:intake_invalid_file_number) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        completed_at: 5.minutes.ago,
        completion_status: :error,
        error_code: :veteran_invalid_file_number
      )
    end

    let!(:intake_refiling_already_processed) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        completed_at: 5.minutes.ago,
        completion_status: :error,
        error_code: :ramp_refiling_already_processed
      )
    end

    let!(:completed_intake) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago
      )
    end

    let!(:intake_fixed_later) do
      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: :canceled,
        cancel_reason: :duplicate_ep
      )

      Intake.create!(
        veteran_file_number: veteran_file_number,
        detail: detail,
        user: user,
        started_at: 3.minutes.ago,
        completed_at: 2.minutes.ago,
        completion_status: :success
      )
    end

    let(:another_detail) do
      create(:ramp_election, veteran_file_number: "54321", notice_date: Time.zone.now, established_at: Time.zone.now)
    end

    let!(:intake_with_manual_election) do
      Intake.create!(
        veteran_file_number: "54321",
        detail: another_detail,
        user: user,
        started_at: 10.minutes.ago,
        completed_at: 5.minutes.ago,
        completion_status: :canceled,
        cancel_reason: :other,
        cancel_other: "I get established manually"
      )
    end

    it "returns included intakes (canceled, actionable errors that have not yet been resolved)" do
      expect(subject).to_not include(completed_intake)
      expect(subject).to include(canceled_intake)
      expect(subject).to include(
        intake_not_accessible,
        intake_not_valid
      )
      expect(subject).to_not include(
        intake_invalid_file_number,
        intake_refiling_already_processed
      )
      expect(subject).to_not include(intake_fixed_later)
      expect(subject).to_not include(intake_with_manual_election)
    end
  end

  context ".user_stats" do
    subject { Intake.user_stats(user) }

    let(:veteran_file_number) { "1234" }
    let(:user) { create(:user) }
    let(:busy_day) { 30.days.ago }

    before do
      5.times do
        Intake.create!(
          user: user,
          veteran_file_number: veteran_file_number,
          detail_type: "SupplementalClaim",
          completed_at: busy_day,
          completion_status: "success"
        )
      end
      5.times do
        Intake.create!(
          user: user,
          veteran_file_number: veteran_file_number,
          detail_type: "HigherLevelReview",
          completed_at: busy_day,
          completion_status: "success"
        )
      end
      Intake.create!(
        user: user,
        veteran_file_number: veteran_file_number,
        detail_type: "SupplementalClaim",
        completed_at: 3.days.ago,
        completion_status: "canceled"
      )
      Intake.create!(
        user: user,
        veteran_file_number: veteran_file_number,
        detail_type: "HigherLevelReview",
        completed_at: 3.days.ago,
        completion_status: "canceled"
      )
      Intake.create!(
        user: user,
        veteran_file_number: veteran_file_number,
        detail_type: "SupplementalClaim",
        completed_at: 61.days.ago,
        completion_status: "success"
      )
      Intake.create!(
        user: create(:user),
        veteran_file_number: veteran_file_number,
        detail_type: "SupplementalClaim",
        completed_at: 3.days.ago,
        completion_status: "success"
      )
    end

    it "returns array of hashes of day-by-day stats" do
      expect(subject).to eq(
        [
          {
            higher_level_review: 5,
            supplemental_claim: 5,
            date: busy_day.to_date.to_s
          }
        ]
      )
    end
  end

  context "#complete_with_status!" do
    it "saves intake with proper tagging" do
      intake.complete_with_status!(:canceled)
      intake.reload

      expect(intake.completed_at).to eq(Time.zone.now)
      expect(intake).to be_canceled
    end
  end

  context "#validate_start" do
    subject { intake.validate_start }

    context "veteran_file_number is null" do
      let(:veteran_file_number) { nil }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "country is null" do
      let(:country) { nil }

      it "does not validate veteran" do
        expect(subject).to be_truthy
      end

      context "RAMP Election Intake" do
        let(:intake) { ramp_election_intake }

        it "adds veteran_not_valid and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("veteran_not_valid")
        end
      end

      context "RAMP Refiling Intake" do
        let(:intake) { ramp_refiling_intake }

        it "adds veteran_not_valid and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("veteran_not_valid")
        end
      end
    end

    context "When Veteran is deceased and missing address" do
      let!(:veteran) do
        Generators::Veteran.build(
          file_number: "64205050",
          address_line1: nil,
          address_line2: nil,
          address_line3: nil,
          zip_code: nil,
          state: nil,
          city: nil,
          country: nil,
          date_of_death: Time.zone.today
        )
      end
      it { is_expected.to be_truthy }
    end

    context "veteran_file_number has fewer than 8 digits" do
      let(:veteran_file_number) { "1234567" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number has more than 9 digits" do
      let(:veteran_file_number) { "1234567899" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number has non-digit characters" do
      let(:veteran_file_number) { "HAXHAXHAX" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran_file_number is VACOLS style" do
      let(:veteran_file_number) { "12341234C" }

      it "adds invalid_file_number and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("invalid_file_number")
      end
    end

    context "veteran not found in bgs" do
      let(:veteran_file_number) { "11111111" }

      it "adds veteran_not_found and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("veteran_not_found")
      end
    end

    context "veteran not accessible by user" do
      before do
        Fakes::BGSService.inaccessible_appeal_vbms_ids = [veteran_file_number]
      end

      it "adds veteran_not_accessible and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("veteran_not_accessible")
      end

      context "Veteran has multiple phone numbers" do
        before do
          allow_any_instance_of(Fakes::BGSService).to receive(:fetch_veteran_info)
            .and_raise(BGS::ShareError.new("NonUniqueResultException"))
        end

        it "adds veteran_has_multiple_phone_numbers and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("veteran_has_multiple_phone_numbers")
        end
      end
    end

    context "veteran address is too long" do
      let!(:veteran) do
        Generators::Veteran.build(
          file_number: "64205050",
          country: country,
          address_line1: "this address is more than 20 characters long"
        )
      end

      it "does not validate Veteran" do
        expect(subject).to be_truthy
      end

      context "RAMP Election Intake" do
        let(:intake) { ramp_election_intake }

        it "adds veteran_not_valid and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("veteran_not_valid")
        end
      end

      context "RAMP Refiling Intake" do
        let(:intake) { ramp_refiling_intake }

        it "adds veteran_not_valid and returns false" do
          expect(subject).to eq(false)
          expect(intake.error_code).to eq("veteran_not_valid")
        end
      end
    end

    context "duplicate in progress intake already exists" do
      let!(:other_intake) do
        TestIntake.create!(
          veteran_file_number: veteran_file_number,
          user: another_user,
          started_at: 15.minutes.ago
        )
      end

      it "adds veteran_not_accessible and returns false" do
        expect(subject).to eq(false)
        expect(intake.error_code).to eq("duplicate_intake_in_progress")
        expect(intake.error_data).to eq(processed_by: "David Schwimmer")
      end
    end

    context "duplicate intake exists, but isn't in progress" do
      let!(:other_intake) do
        TestIntake.create!(
          veteran_file_number: veteran_file_number,
          user: another_user,
          started_at: 15.minutes.ago,
          completed_at: 10.minutes.ago
        )
      end

      it { is_expected.to be_truthy }
    end

    context "in progress intake exists on same file number, but not same type" do
      let!(:other_intake) do
        AnotherTestIntake.create!(
          veteran_file_number: veteran_file_number,
          user: another_user,
          started_at: 15.minutes.ago
        )
      end

      it { is_expected.to be_truthy }
    end

    context "in progress intake exists on same type, but not same file number" do
      let!(:other_intake) do
        TestIntake.create!(
          veteran_file_number: "22226666",
          user: another_user,
          started_at: 15.minutes.ago
        )
      end

      it { is_expected.to be_truthy }
    end

    context "when number is valid (even with extra spaces)" do
      let(:veteran_file_number) { "  64205050  " }
      it { is_expected.to be_truthy }
    end
  end

  context "#start!" do
    subject { intake.start! }
    let(:detail) { nil }

    context "not valid to start" do
      let(:veteran_file_number) { "NOTVALID" }

      it "does not save intake and returns false" do
        expect(subject).to be_falsey

        expect(intake).to have_attributes(
          started_at: Time.zone.now,
          completed_at: Time.zone.now,
          completion_status: "error",
          error_code: "invalid_file_number",
          detail: nil
        )
      end
    end

    context "valid to start" do
      let(:ramp_election_detail) do
        build(
          :ramp_election,
          veteran_file_number: veteran_file_number,
          notice_date: Time.zone.now,
          receipt_date: 5.days.ago,
          option_selected: :supplemental_claim
        )
      end

      let(:higher_level_review) do
        build(:higher_level_review,
              veteran_file_number: veteran_file_number,
              receipt_date: 5.days.ago,
              legacy_opt_in_approved: false)
      end

      let!(:expired_intake) do
        RampElectionIntake.create!(
          veteran_file_number: veteran_file_number,
          detail: ramp_election_detail,
          user: user,
          started_at: 25.hours.ago
        )
      end

      let!(:expired_other_intake) do
        HigherLevelReviewIntake.create!(
          veteran_file_number: veteran_file_number,
          detail: higher_level_review,
          user: another_user,
          started_at: 25.hours.ago
        )
      end

      before do
        higher_level_review.create_claimant!(participant_id: "5382910292", payee_code: "10")
      end

      it "clears expired intakes and creates new intake" do
        subject

        expect(intake).to have_attributes(
          veteran_file_number: veteran_file_number,
          started_at: Time.zone.now,
          detail: intake.find_or_build_initial_detail,
          user: user
        )

        # Ramp Election intake details are not destroyed
        expect(expired_intake.reload).to have_attributes(completion_status: "expired")
        expect(expired_intake.detail).to have_attributes(
          receipt_date: nil,
          option_selected: nil
        )

        # Non-Ramp Election intake details are destroyed
        expect(expired_other_intake.reload).to have_attributes(completion_status: "expired")
        expect(expired_other_intake.detail).to be_nil
        expect(Claimant.find_by(participant_id: "5382910292")).to be_nil
      end
    end
  end

  context "#start_completion!" do
    subject { intake.start_completion! }

    it "sets completion_started_at to now" do
      subject
      expect(intake.completion_started_at).to eq(Time.zone.now)
    end
  end

  context "#abort_completion!" do
    subject { intake.abort_completion! }

    it "undoes whatever start_completion! does" do
      intake.save!
      attributes = intake.attributes

      intake.start_completion!
      expect(intake.attributes).not_to eql(attributes)

      subject
      expect(intake.attributes).to eql(attributes)
    end
  end

  context "#pending?" do
    subject { intake.pending? }

    context "when completion_started_at is nil" do
      it { is_expected.to be false }
    end

    context "when completion_start_at is not nil and within timeout" do
      let(:completion_started_at) { 4.minutes.ago }

      it { is_expected.to be true }
    end

    context "when completion_start_at is not nil and exceeded timeout" do
      let(:completion_started_at) { 6.minutes.ago }

      it { is_expected.to be false }
    end
  end
end
