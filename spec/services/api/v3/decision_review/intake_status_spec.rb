# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

context Api::V3::DecisionReview::IntakeStatus, :postgres do
  let(:veteran_file_number) { "123456789" }

  let(:higher_level_review) do
    create(:higher_level_review, veteran_file_number: veteran_file_number)
  end

  let(:intake) do
    create(:intake, veteran_file_number: veteran_file_number, detail: decision_review)
  end

  context "#to_json" do
    subject { intake_status = described_class.new(intake) }

    context do
      let(:decision_review) do
        hlr = higher_level_review

        asyncable_status = "dog"
        allow(hlr).to receive(:asyncable_status) { asyncable_status }

        uuid = "cat"
        allow(hlr).to receive(:uuid) { uuid }

        hlr
      end

      it("returns the correctly-formatted JSON:API response when the intake has a decision review") do
        expect(intake_status.to_json).to be_a(Hash)
        expect(intake_status.to_json.keys).to contain_exactly(:data)
        expect(intake_status.to_json[:data]).to be_a(Hash)
        expect(intake_status.to_json[:data].keys).to contain_exactly(:type, :id, :attributes)
        expect(intake_status.to_json[:data][:type]).to eq(decision_review.class.name)
        expect(intake_status.to_json[:data][:id]).to eq(uuid)
        expect(intake_status.to_json[:data][:attributes]).to be_a(Hash)
        expect(intake_status.to_json[:data][:attributes].keys).to contain_exactly(:status)
        expect(intake_status.to_json[:data][:attributes][:status]).to eq(asyncable_status)
      end
    end

    context do
      let(:decision_review) { nil }

      it("returns an error when the intake does not have a decision review") do
        expect(subject.to_json).to be_a(Hash)
        expect(subject.to_json.keys).to contain_exactly(:errors)
        expect(subject.to_json[:errors]).to be_a(Array)
        expect(subject.to_json[:errors].length).to eq(1)
        expect(subject.to_json[:errors][0]).to be_a(Hash)
        expect(subject.to_json[:errors][0].keys).to contain_exactly(:status, :code, :title)
        expect(subject.to_json[:errors][0][:status]).to be > 399
      end
    end
  end

  context "#http_status" do
    context do
      let(:decision_review) { nil }
    it("returns NO_DECISION_REVIEW_HTTP_STATUS when the intake has no decision review") do
      intake = create_intake[]

      intake_status = new_intake_status[intake]

      expect(intake_status.http_status).to eq(
        Api::V3::DecisionReview::IntakeStatus::NO_DECISION_REVIEW_HTTP_STATUS
      )
    end

    it("returns NOT_SUBMITTED_HTTP_STATUS if asyncable_status isn't :submitted") do
      decision_review = create_higher_level_review

      asyncable_status = "zebra"
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      intake = create_intake[decision_review]

      intake_status = new_intake_status[intake]

      expect(intake_status.http_status).to eq(
        Api::V3::DecisionReview::IntakeStatus::NOT_SUBMITTED_HTTP_STATUS
      )
    end

    it("returns SUBMITTED_HTTP_STATUS if asyncable_status is :submitted") do
      decision_review = create_higher_level_review

      asyncable_status = :submitted
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      intake = create_intake[decision_review]

      intake_status = new_intake_status[intake]

      expect(intake_status.http_status).to eq(
        Api::V3::DecisionReview::IntakeStatus::SUBMITTED_HTTP_STATUS
      )
    end
  end

  context "#http_status_for_new_intake" do
    it("returns NO_DECISION_REVIEW_HTTP_STATUS when the intake has no decision review") do
      intake = create_intake[]

      intake_status = new_intake_status[intake]

      expect(intake_status.http_status_for_new_intake).to eq(
        Api::V3::DecisionReview::IntakeStatus::NO_DECISION_REVIEW_HTTP_STATUS
      )
    end

    it("returns NOT_SUBMITTED_HTTP_STATUS_FOR_NEW_INTAKE if asyncable_status isn't :submitted") do
      decision_review = create_higher_level_review

      asyncable_status = "zebra"
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      intake = create_intake[decision_review]

      intake_status = new_intake_status[intake]

      expect(intake_status.http_status_for_new_intake).to eq(
        Api::V3::DecisionReview::IntakeStatus::NOT_SUBMITTED_HTTP_STATUS_FOR_NEW_INTAKE
      )
    end

    it("returns SUBMITTED_HTTP_STATUS if asyncable_status is :submitted") do
      decision_review = create_higher_level_review

      asyncable_status = :submitted
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      intake = create_intake[decision_review]

      intake_status = new_intake_status[intake]

      expect(intake_status.http_status_for_new_intake).to eq(
        Api::V3::DecisionReview::IntakeStatus::SUBMITTED_HTTP_STATUS
      )
    end
  end
end
