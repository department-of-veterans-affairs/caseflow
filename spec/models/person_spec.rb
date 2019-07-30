# frozen_string_literal: true

require "rails_helper"

describe Person do
  let(:known_fake_participant_id) { "1129318238" }

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

  describe "#update_cached_attributes!" do
    let(:participant_id) { known_fake_participant_id }
    let(:person) { create(:person, participant_id: participant_id) }
    let(:bgs_person) { Fakes::BGSService.new.fetch_person_info(participant_id) }
    let(:attributes) { [:first_name, :last_name, :middle_name, :name_suffix] }

    it "populates via single method call" do
      attributes.each do |attr|
        expect(person[attr]).to be_nil
      end

      person.update_cached_attributes!

      attributes.each do |attr|
        expect(person[attr]).to eq(bgs_person[attr])
      end
    end

    it "populates attributes on accessor method use" do
      attributes.each do |attr|
        expect(person[attr]).to be_nil
      end

      attributes.each do |attr|
        expect(person.send(attr)).to eq(bgs_person[attr])
      end
    end
  end

  describe "#stale_attributes?" do
    let(:participant_id) { known_fake_participant_id }
    let(:first_name) { bgs_person[:first_name] }
    let(:middle_name) { bgs_person[:middle_name] }
    let(:last_name) { bgs_person[:last_name] }
    let(:date_of_birth) { bgs_person[:birth_date] }
    let(:name_suffix) { bgs_person[:name_suffix] }

    let(:person) do
      create(
        :person,
        first_name: first_name,
        last_name: last_name,
        middle_name: middle_name,
        name_suffix: name_suffix,
        date_of_birth: date_of_birth,
        participant_id: participant_id
      )
    end

    let(:bgs_person) { Fakes::BGSService.new.fetch_person_info(participant_id) }

    subject { person.stale_attributes? }

    context "no difference" do
      it { is_expected.to eq(false) }
    end

    context "first_name is nil" do
      let(:first_name) { nil }

      it { is_expected.to eq(true) }
    end

    context "last_name is nil" do
      let(:last_name) { nil }

      it { is_expected.to eq(true) }
    end

    context "first_name does not match BGS" do
      let(:first_name) { "Changed" }

      it { is_expected.to eq(true) }
    end

    context "last_name does not match BGS" do
      let(:last_name) { "Changed" }

      it { is_expected.to eq(true) }
    end

    context "middle_name does not match BGS" do
      let(:middle_name) { "Changed" }

      it { is_expected.to eq(true) }
    end

    context "name_suffix does not match BGS" do
      let(:name_suffix) { "Changed" }

      it { is_expected.to eq(true) }
    end
  end
end
