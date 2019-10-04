# frozen_string_literal: true

require "support/database_cleaner"
require "rails_helper"

context Api::V3::DecisionReview::IntakeStatus, :postgres do
  let(:veteran_file_number) { "123456789" }

  def fake_intake(detail = nil)
    Intake.create!(
      user: Generators::User.build,
      veteran_file_number: veteran_file_number,
      detail: detail,
    )
  end

  def fake_higher_level_review
    HigherLevelReview.create!(veteran_file_number: veteran_file_number)
  end

  def fake_supplemental_claim
    SupplementalClaim.create!(veteran_file_number: veteran_file_number)
  end

  def fake_appeal
    Appeal.create!(veteran_file_number: veteran_file_number)
  end

  def new_intake_status(intake)
    # Api::V3::DecisionReview::IntakeStatus.new(intake, reload: false)
    Api::V3::DecisionReview::IntakeStatus.new(intake)
  end

  context "#to_json" do
    it("returns the correctly-formatted JSON:API response when the intake has a decision review") do
      decision_review = fake_higher_level_review

      asyncable_status = "dog"
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      uuid = "cat"
      allow(decision_review).to receive(:uuid) { uuid }

      intake = fake_intake(decision_review)

      intake_status = new_intake_status(intake)

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

    it("returns an error when the intake does not have a decision review") do
      intake = fake_intake

      intake_status = new_intake_status(intake)

      expect(intake_status.to_json).to be_a(Hash)
      expect(intake_status.to_json.keys).to contain_exactly(:errors)
      expect(intake_status.to_json[:errors]).to be_a(Array)
      expect(intake_status.to_json[:errors].length).to eq(1) 
      expect(intake_status.to_json[:errors][0]).to be_a(Hash) 
      expect(intake_status.to_json[:errors][0].keys).to contain_exactly(:status, :code, :title) 
      expect(intake_status.to_json[:errors][0][:status]).to be > 399
    end
  end

  context "#http_status" do
    it("returns NO_DECISION_REVIEW_HTTP_STATUS when the intake has no decision review") do
      intake = fake_intake

      intake_status = new_intake_status(intake)

      expect(intake_status.http_status).to eq(Api::V3::DecisionReview::IntakeStatus::NO_DECISION_REVIEW_HTTP_STATUS)
    end

    it("returns NOT_SUBMITTED_HTTP_STATUS if asyncable_status isn't :submitted") do
      decision_review = fake_higher_level_review

      asyncable_status = "zebra"
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      intake = fake_intake(decision_review)

      intake_status = new_intake_status(intake)

      expect(intake_status.http_status).to eq(Api::V3::DecisionReview::IntakeStatus::NOT_SUBMITTED_HTTP_STATUS)
    end

    it("returns SUBMITTED_HTTP_STATUS if asyncable_status is :submitted") do
      decision_review = fake_higher_level_review

      asyncable_status = :submitted
      allow(decision_review).to receive(:asyncable_status) { asyncable_status }

      intake = fake_intake(decision_review)

      intake_status = new_intake_status(intake)

      expect(intake_status.http_status).to eq(Api::V3::DecisionReview::IntakeStatus::SUBMITTED_HTTP_STATUS)
    end
  end
end
