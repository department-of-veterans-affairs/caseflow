# frozen_string_literal: true

context Api::V3::DecisionReview::IntakeStatus, :postgres do
  let(:veteran_file_number) { "123456789" }

  let(:higher_level_review) do
    hlr = create(:higher_level_review, veteran_file_number: veteran_file_number)
    hlr.reload # set uuid
    allow(hlr).to receive(:asyncable_status) { asyncable_status }
    hlr
  end

  let(:decision_review) { higher_level_review }

  let(:intake) do
    create(:intake, veteran_file_number: veteran_file_number, detail: decision_review)
  end

  subject { described_class.new(intake) }

  context "#to_json" do
    let(:json) { subject.to_json }

    context "when asyncable status is processed" do
      let(:asyncable_status) { :processed }

      it "returns the correct json" do
        expect(subject.to_json).to be_a(Hash)
      end

      it "is correctly shaped" do
        expect(subject.to_json.keys).to contain_exactly(:data)
        expect(subject.to_json[:data]).to be_a(Hash)
        expect(subject.to_json[:data].keys).to contain_exactly(:type, :id, :attributes)
        expect(subject.to_json[:data][:attributes]).to be_a(Hash)
        expect(subject.to_json[:data][:attributes].keys).to contain_exactly(:status)
      end

      it "has the correct values" do
        expect(subject.to_json[:data][:type]).to eq(decision_review.class.name)
        expect(subject.to_json[:data][:id]).to eq(decision_review.uuid)
        expect(subject.to_json[:data][:attributes][:status]).to eq(asyncable_status)
      end
    end

    context "when asyncable status isn't :processed" do
      let(:asyncable_status) { "dog" }

      it "returns json" do
        expect(json).to be_a(Hash)
      end

      it "is correctly shaped" do
        expect(json.keys).to contain_exactly(:data)
        expect(json[:data]).to be_a(Hash)
        expect(json[:data].keys).to contain_exactly(:type, :id, :attributes)
        expect(json[:data][:attributes]).to be_a(Hash)
        expect(json[:data][:attributes].keys).to contain_exactly(:status)
      end

      it "has the correct values" do
        expect(json[:data][:type]).to eq(decision_review.class.name)
        expect(json[:data][:id]).to eq(decision_review.uuid)
        expect(json[:data][:attributes][:status]).to eq(asyncable_status)
      end
    end

    context "when the intake doesn't have a decision review" do
      let(:decision_review) { nil }

      it "returns json" do
        expect(subject.to_json).to be_a(Hash)
      end

      it "is correctly shaped" do
        expect(subject.to_json.keys).to contain_exactly(:errors)
        expect(subject.to_json[:errors]).to be_a(Array)
        expect(subject.to_json[:errors].length).to eq(1)
        expect(subject.to_json[:errors][0]).to be_a(Hash)
        expect(subject.to_json[:errors][0].keys).to contain_exactly(:status, :code, :title)
      end

      it "has an error http status" do
        expect(subject.to_json[:errors][0][:status]).to be > 399
      end
    end
  end

  context "#http_status" do
    context "when asyncable status is processed" do
      let(:asyncable_status) { :processed }

      it "returns PROCESSED_HTTP_STATUS" do
        expect(subject.http_status).to eq(
          Api::V3::DecisionReview::IntakeStatus::PROCESSED_HTTP_STATUS
        )
      end
    end

    context "when asyncable status isn't :processed" do
      let(:asyncable_status) { "zebra" }

      it "returns NOT_PROCESSED_HTTP_STATUS" do
        expect(subject.http_status).to eq(
          Api::V3::DecisionReview::IntakeStatus::NOT_PROCESSED_HTTP_STATUS
        )
      end
    end

    context "when the intake doesn't have a decision review" do
      let(:decision_review) { nil }

      it "returns NO_DECISION_REVIEW_HTTP_STATUS" do
        expect(subject.http_status).to eq(
          Api::V3::DecisionReview::IntakeStatus::NO_DECISION_REVIEW_HTTP_STATUS
        )
      end
    end
  end

  context "#http_status_for_new_intake" do
    context "when asyncable status is processed" do
      let(:asyncable_status) { :processed }

      it "returns PROCESSED_HTTP_STATUS" do
        expect(subject.http_status_for_new_intake).to eq(
          Api::V3::DecisionReview::IntakeStatus::PROCESSED_HTTP_STATUS
        )
      end
    end

    context "when asyncable status isn't :processed" do
      let(:asyncable_status) { "zebra" }

      it "returns NOT_PROCESSED_HTTP_STATUS_FOR_NEW_INTAKE" do
        expect(subject.http_status_for_new_intake).to eq(
          Api::V3::DecisionReview::IntakeStatus::NOT_PROCESSED_HTTP_STATUS_FOR_NEW_INTAKE
        )
      end
    end

    context "when the intake doesn't have a decision review" do
      let(:decision_review) { nil }

      it "returns NO_DECISION_REVIEW_HTTP_STATUS" do
        expect(subject.http_status_for_new_intake).to eq(
          Api::V3::DecisionReview::IntakeStatus::NO_DECISION_REVIEW_HTTP_STATUS
        )
      end
    end
  end
end
