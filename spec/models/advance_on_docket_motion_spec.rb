# frozen_string_literal: true

describe AdvanceOnDocketMotion, :postgres do
  let(:user_id) { create(:user).id }

  describe "scopes" do
    let(:motion_reasons) { described_class.reasons.keys }
    let(:grant_or_deny) { [true, false] }
    let!(:people_ids) { [create(:person).id, create(:person).id] }
    let!(:creation_dates) { [30.days.ago, Time.zone.now] }
    let!(:motions) do
      motion_reasons.map do |reason|
        grant_or_deny.map do |granted|
          people_ids.map do |person_id|
            creation_dates.map do |creation_date|
              described_class.create!(
                created_at: creation_date,
                person_id: person_id,
                granted: granted,
                reason: reason,
                user_id: user_id
              )
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

    describe "#eligable_due_to_age" do
      it "Returns all motions where the advance reason is age related" do
        expect(described_class.eligable_due_to_age.count).to eq motions.count / motion_reasons.count
        expect(described_class.eligable_due_to_age.pluck(:reason).uniq).to eq [described_class.reasons[:age]]
      end
    end

    describe "#eligable_due_to_date" do
      it "Returns all motions created after receipt date, but not age related motions" do
        non_age_motions = described_class.where.not(id: described_class.age)
        expect(described_class.eligable_due_to_date(1.day.ago).count).to eq non_age_motions.count / creation_dates.count
        expect(described_class.eligable_due_to_date(31.days.ago).count).to eq non_age_motions.count
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
    let(:reason) {  described_class.reasons[:financial_distress] }

    before do
      described_class.create!(
        created_at: 5.days.ago,
        person_id: person_id,
        granted: granted,
        reason: reason,
        user_id: user_id
      )
    end
    subject { described_class.granted_for_person?(person_id, appeal_receipt_date) }

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
          let(:appeal_receipt_date) { 30.days.ago }

          it { is_expected.to be true }
        end
      end

      context "and the motion was granted after the appeal receipt date" do
        let(:reason) { described_class.reasons[:age] }

        it { is_expected.to be true }
      end
    end
  end

  describe "#create_or_update_by_appeal" do
    let(:appeal) { create(:appeal, receipt_date: appeal_receipt_date, claimants: [claimant]) }
    let(:claimant) { create(:claimant) }
    let(:appeal_receipt_date) { Time.zone.now }
    let(:reason) {  described_class.reasons[:financial_distress] }
    let(:attrs) { { reason: described_class.reasons[:other], granted: true } }

    before do
      described_class.create!(
        created_at: 5.days.ago,
        person_id: claimant.person.id,
        granted: false,
        reason: reason,
        user_id: user_id
      )
    end

    subject { described_class.create_or_update_by_appeal(appeal, attrs) }

    context "when has no motion created after the appeal receipt date" do
      it "creates a new motion" do
        subject
        motions = appeal.claimant.person.advance_on_docket_motions
        expect(motions.count).to eq 2
        expect(motions.first.granted).to be(false)
        expect(motions.first.reason).to eq(described_class.reasons[:financial_distress])
        expect(motions.second.granted).to be(true)
        expect(motions.second.reason).to eq(described_class.reasons[:other])
      end
    end

    context "and the motion was granted after the appeal receipt date" do
      let(:appeal_receipt_date) { 30.days.ago }

      context "when the motion reason is not age" do
        it "updates the previous motion" do
          subject
          motions = appeal.claimant.person.advance_on_docket_motions
          expect(motions.count).to eq 1
          expect(motions.first.granted).to be(true)
          expect(motions.first.reason).to eq(described_class.reasons[:other])
        end
      end

      context "when the motion reason is age" do
        let(:reason) {  described_class.reasons[:age] }

        it "creates a new motion" do
          subject
          motions = appeal.claimant.person.advance_on_docket_motions
          expect(motions.count).to eq 2
          expect(motions.first.granted).to be(false)
          expect(motions.first.reason).to eq(described_class.reasons[:age])
          expect(motions.second.granted).to be(true)
          expect(motions.second.reason).to eq(attrs[:reason])
        end
      end
    end
  end
end
