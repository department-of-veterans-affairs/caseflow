# frozen_string_literal: true

describe AdvanceOnDocketMotion, :postgres do
  describe "scopes" do
    let(:user_id) { create(:user).id }
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
      it "Returns all motions created after reciept date, but not age related motions" do
        non_age_motions = described_class.where.not(id: described_class.age)
        expect(described_class.eligable_due_to_date(1.day.ago).count).to eq non_age_motions.count / creation_dates.count
        expect(described_class.eligable_due_to_date(31.days.ago).count).to eq non_age_motions.count
      end
    end

    describe "#for_person" do
      it "Returns all motions related to povided person" do
        expect(described_class.for_person(people_ids.first).count).to eq motions.count / people_ids.count
        expect(described_class.for_person(people_ids.first).pluck(:person_id).uniq).to eq [people_ids.first]
      end
    end
  end

  describe "#granted_for_person?" do
    subject { granted_for_person?(person_id, appeal_receipt_date) }
    context "when the person has no eligable motions" do
    end
  end
end
