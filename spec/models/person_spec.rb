# frozen_string_literal: true

describe Person do
  context "#date_of_birth" do
    subject { create(:person, date_of_birth: date_of_birth) }

    context "when date of birth is already present" do
      let(:date_of_birth) { 20.years.ago }

      it "should not call BGS" do
        expect(subject.date_of_birth).to eq 20.years.ago.to_date
      end
    end

    context "when date of birth is not present" do
      let(:date_of_birth) { nil }

      it "should call BGS" do
        expect(subject.date_of_birth).to eq BGSService.new.fetch_person_info(
          subject.participant_id
        )[:birth_date].to_date
      end
    end
  end
end
