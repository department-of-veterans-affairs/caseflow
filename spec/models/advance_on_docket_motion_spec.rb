# frozen_string_literal: true

describe AdvanceOnDocketMotion, :postgres do
  let(:user_id) { create(:user).id }

  describe "scopes" do
    let(:motion_reasons) { described_class.reasons.keys }
    let(:grant_or_deny) { [true, false] }
    let!(:people_ids) { [create(:person).id, create(:person).id] }
    let!(:creation_dates) { [30.days.ago, Time.zone.now] }
    let!(:appeals) { create_list(:appeal, 2) }
    let!(:motions) do
      motion_reasons.map do |reason|
        grant_or_deny.map do |granted|
          people_ids.map do |person_id|
            creation_dates.map do |creation_date|
              appeals.map do |appeal|
                described_class.create!(
                  created_at: creation_date,
                  person_id: person_id,
                  granted: granted,
                  reason: reason,
                  user_id: user_id,
                  appeal: appeal
                )
              end
            end
          end
        end
      end.flatten
    end

    describe "#granted" do
      it "Returns all granted motions" do
        expect(described_class.granted.count).to eq motions.count / grant_or_deny.count
        expect(described_class.granted.pluck(:granted).uniq).to eq [true]
      end
    end

    describe "#eligible_due_to_age" do
      it "Returns all motions where the advance reason is age related" do
        expect(described_class.eligible_due_to_age.count).to eq motions.count / motion_reasons.count
        expect(described_class.eligible_due_to_age.pluck(:reason).uniq).to eq [described_class.reasons[:age]]
      end
    end

    describe "#eligible_due_to_appeal" do
      it "Returns all motions linked to the appeal, but not age related motions" do
        expect(described_class.eligible_due_to_appeal(appeals.first).pluck(:appeal_id).uniq).to eq [appeals.first.id]
        expect(
          described_class.eligible_due_to_appeal(appeals.first).pluck(:reason).include?(described_class.reasons[:age])
        ).to be false
      end
    end

    describe "#for_person" do
      it "Returns all motions related to provided person" do
        expect(described_class.for_person(people_ids.first).count).to eq motions.count / people_ids.count
        expect(described_class.for_person(people_ids.first).pluck(:person_id).uniq).to eq [people_ids.first]
      end
    end
  end

  describe "#granted_for_person?" do
    let(:appeal_receipt_date) { Time.zone.now }
    let(:person_id) { 1 }
    let(:granted) { false }
    let(:reason) { described_class.reasons[:financial_distress] }
    let(:appeal) { create(:appeal, receipt_date: appeal_receipt_date) }
    let(:appeal_on_motion) { create(:appeal) }

    before do
      described_class.create!(
        created_at: 5.days.ago,
        person_id: person_id,
        granted: granted,
        reason: reason,
        user_id: user_id,
        appeal: appeal_on_motion
      )
    end

    subject { described_class.granted_for_person?(person_id, appeal) }

    context "when the person has no granted motions" do
      it { is_expected.to be false }
    end

    context "when the person has granted motions" do
      let(:granted) { true }

      context "but has no motions created after the appeal receipt date" do
        context "when the motion reason is not age" do
          it { is_expected.to be false }
        end

        context "when the motion reason is age" do
          let(:reason) { described_class.reasons[:age] }

          it { is_expected.to be true }
        end
      end

      context "and the motion is linked to the appeal" do
        let(:appeal_on_motion) { appeal }

        it { is_expected.to be true }
      end

      context "and the motion was granted after the appeal receipt date" do
        let(:appeal_receipt_date) { 30.days.ago }

        it { is_expected.to be false }
      end
    end
  end

  describe "#create_or_update_by_appeal" do
    let(:appeal) { create(:appeal, claimants: [claimant]) }
    let(:claimant) { create(:claimant) }
    let(:reason) { described_class.reasons[:financial_distress] }
    let(:appeal_on_motion) { create(:appeal) }
    let(:attrs) { { reason: reason, granted: true } }

    subject { described_class.create_or_update_by_appeal(appeal, attrs) }

    context "when there is no motion associated with the appeal" do
      context "when the motion is not age-related" do
        it "creates a new motion" do
          subject
          motions = appeal.claimant.person.advance_on_docket_motions
          expect(motions.count).to eq 1
          expect(motions.first.granted).to be(true)
          expect(motions.first.reason).to eq(described_class.reasons[:financial_distress])
        end
      end

      context "when the motion is age-related" do
        let(:reason) { described_class.reasons[:age] }
        it "creates a new motion" do
          subject
          motions = appeal.claimant.person.advance_on_docket_motions
          expect(motions.count).to eq 1
          expect(motions.first.granted).to be(true)
          expect(motions.first.reason).to eq(described_class.reasons[:age])
        end
      end
    end

    context "when there is an existing motion for the appeal" do
      let(:appeal_on_motion) { appeal }

      # Because we're mostly testing updates, create an initial AOD motion first:
      before do
        described_class.create!(
          person_id: claimant.person.id,
          granted: false,
          reason: initial_reason,
          user_id: user_id,
          appeal: appeal_on_motion
        )
      end

      context "whose previous motion reason is not age" do
        let(:initial_reason) { described_class.reasons[:other] }
        context "creating an age-related motion" do
          let(:reason) { described_class.reasons[:age] }

          it "creates a new age-related motion" do
            subject
            motions = appeal.claimant.person.advance_on_docket_motions
            expect(motions.count).to eq 2
            expect(motions.first.granted).to be(false)
            expect(motions.first.reason).to eq(described_class.reasons[:other])
            expect(motions.second.granted).to eq(true)
            expect(motions.second.reason).to eq(described_class.reasons[:age])
          end
        end

        context "creating a non-age-related motion" do
          let(:reason) { described_class.reasons[:serious_illness] }

          it "updates the existing motion" do
            subject
            motions = appeal.claimant.person.advance_on_docket_motions
            expect(motions.count).to eq 1
            expect(motions.first.granted).to be(true)
            expect(motions.first.reason).to eq(described_class.reasons[:serious_illness])
          end
        end
      end

      context "whose reason is age" do
        let(:initial_reason) { described_class.reasons[:age] }

        context "creating an age-related motion" do
          let(:reason) { described_class.reasons[:age] }

          it "updates the existing motion" do
            subject
            motions = appeal.claimant.person.advance_on_docket_motions
            expect(motions.count).to eq 1
            expect(motions.first.granted).to be(true)
            expect(motions.first.reason).to eq(described_class.reasons[:age])
          end
        end

        context "creating a non-age-related motion" do
          let(:reason) { described_class.reasons[:other] }

          it "creates a non-age-related motion" do
            subject
            motions = appeal.claimant.person.advance_on_docket_motions
            expect(motions.count).to eq 2
            expect(motions.first.granted).to be(false)
            expect(motions.first.reason).to eq(described_class.reasons[:age])
            expect(motions.second.granted).to be(true)
            expect(motions.second.reason).to eq(described_class.reasons[:other])
          end
        end
      end
    end
  end

  describe "#non_age_related_motion?" do
    subject { described_class.new(reason: reason).non_age_related_motion? }

    context "when the reason is 'age'" do
      let(:reason) { described_class.reasons[:age] }
      it { is_expected.to be false }
    end

    [
      described_class.reasons[:serious_illness],
      described_class.reasons[:financial_distress],
      described_class.reasons[:other]
    ].each do |reason|
      context "When the reason is '#{reason}'" do
        let(:reason) { reason }
        it { is_expected.to be true }
      end
    end
  end
end
