# frozen_string_literal: true

require "test_prof/recipes/rspec/let_it_be"

describe Api::V3::Issues::Ama::RequestIssueSerializer, :postgres do
  let(:user) { Generators::User.build }
  let(:vet) { create(:veteran) }
  let(:epe) { create(:end_product_establishment) }
  let(:request_issue) do
    create(:request_issue, :with_associated_decision_issue, edited_description: "Somehow edited",
                                                            end_product_establishment_id: epe.id,
                                                            veteran_participant_id: vet.participant_id)
  end
  let(:request_issue_2) do
    create(:request_issue, :with_associated_decision_issue, end_product_establishment_id: epe.id,
                                                            veteran_participant_id: vet.participant_id)
  end
  let!(:appeal_intake) do
    AppealIntake.create(
      user: user,
      detail: request_issue.decision_review,
      veteran_file_number: vet.file_number,
      started_at: 2.days.ago,
      completed_at: Time.zone.now,
      completion_status: "success"
    )
  end

  context "request issue object" do
    it "should have all eligiblity fields" do
      serialized_request_issue = Api::V3::Issues::Ama::RequestIssueSerializer.new(request_issue)
        .serializable_hash[:data][:attributes]
      expect(serialized_request_issue.key?(:id)).to eq true
      expect(serialized_request_issue.key?(:added_by_station_id)).to eq true
      expect(serialized_request_issue.key?(:added_by_css_id)).to eq true
      expect(serialized_request_issue[:added_by_station_id]).to eq user.station_id
      expect(serialized_request_issue[:added_by_css_id]).to eq user.css_id
      expect(serialized_request_issue.key?(:legacy_opt_in_approved)).to eq true
      expect(serialized_request_issue.key?(:same_office)).to eq true
      expect(serialized_request_issue.key?(:development_item_reference_id)).to eq true
      expect(serialized_request_issue.key?(:benefit_type)).to eq true
      expect(serialized_request_issue.key?(:closed_status)).to eq true
      expect(serialized_request_issue.key?(:contention_reference_id)).to eq true
      expect(serialized_request_issue.key?(:contested_decision_issue_id)).to eq true
      expect(serialized_request_issue.key?(:contested_issue_description)).to eq true
      expect(serialized_request_issue.key?(:contested_rating_decision_reference_id)).to eq true
      expect(serialized_request_issue.key?(:contested_rating_issue_diagnostic_code)).to eq true
      expect(serialized_request_issue.key?(:contested_rating_issue_profile_date)).to eq true
      expect(serialized_request_issue.key?(:contested_rating_issue_reference_id)).to eq true
      expect(serialized_request_issue.key?(:correction_type)).to eq true
      expect(serialized_request_issue.key?(:created_at)).to eq true
      expect(serialized_request_issue.key?(:decision_date)).to eq true
      expect(serialized_request_issue.key?(:decision_review_id)).to eq true
      expect(serialized_request_issue.key?(:decision_review_type)).to eq true
      expect(serialized_request_issue.key?(:edited_by_css_id)).to eq true
      expect(serialized_request_issue.key?(:edited_by_station_id)).to eq true
      expect(serialized_request_issue.key?(:edited_description)).to eq true
      expect(serialized_request_issue.key?(:end_product_establishment_id)).to eq true
      expect(serialized_request_issue.key?(:ineligible_due_to_id)).to eq true
      expect(serialized_request_issue.key?(:ineligible_reason)).to eq true
      expect(serialized_request_issue.key?(:is_unidentified)).to eq true
      expect(serialized_request_issue.key?(:nonrating_issue_bgs_id)).to eq true
      expect(serialized_request_issue.key?(:nonrating_issue_bgs_source)).to eq true
      expect(serialized_request_issue.key?(:nonrating_issue_category)).to eq true
      expect(serialized_request_issue.key?(:nonrating_issue_description)).to eq true
      expect(serialized_request_issue.key?(:notes)).to eq true
      expect(serialized_request_issue.key?(:ramp_claim_id)).to eq true
      expect(serialized_request_issue.key?(:removed_by_css_id)).to eq true
      expect(serialized_request_issue.key?(:removed_by_station_id)).to eq true
      expect(serialized_request_issue.key?(:split_issue_status)).to eq true
      expect(serialized_request_issue.key?(:untimely_exemption)).to eq true
      expect(serialized_request_issue.key?(:untimely_exemption_notes)).to eq true
      expect(serialized_request_issue.key?(:updated_at)).to eq true
      expect(serialized_request_issue.key?(:vacols_id)).to eq true
      expect(serialized_request_issue.key?(:vacols_sequence_id)).to eq true
      expect(serialized_request_issue.key?(:verified_unidentified_issue)).to eq true
      expect(serialized_request_issue.key?(:veteran_participant_id)).to eq true
      expect(serialized_request_issue.key?(:withdrawn_by_css_id)).to eq true
      expect(serialized_request_issue.key?(:withdrawn_by_station_id)).to eq true
      expect(serialized_request_issue.key?(:caseflow_considers_decision_review_active)).to eq true
      expect(serialized_request_issue.key?(:caseflow_considers_issue_active)).to eq true
      expect(serialized_request_issue.key?(:caseflow_considers_title_of_active_review)).to eq true
      expect(serialized_request_issue.key?(:caseflow_considers_eligible)).to eq true
      expect(serialized_request_issue.key?(:claimant_participant_id)).to eq true
      expect(serialized_request_issue.key?(:decision_issues)).to eq true
      expect(serialized_request_issue.key?(:claim_id)).to eq true
      expect(serialized_request_issue.key?(:claim_errors)).to eq true

      serialized_decision_issue = serialized_request_issue[:decision_issues].first
      expect(serialized_decision_issue.key?(:id)).to eq true
      expect(serialized_decision_issue.key?(:caseflow_decision_date)).to eq true
      expect(serialized_decision_issue.key?(:created_at)).to eq true
      expect(serialized_decision_issue.key?(:decision_text)).to eq true
      expect(serialized_decision_issue.key?(:deleted_at)).to eq true
      expect(serialized_decision_issue.key?(:description)).to eq true
      expect(serialized_decision_issue.key?(:diagnostic_code)).to eq true
      expect(serialized_decision_issue.key?(:disposition)).to eq true
      expect(serialized_decision_issue.key?(:end_product_last_action_date)).to eq true
      expect(serialized_decision_issue.key?(:percent_number)).to eq true
      expect(serialized_decision_issue.key?(:rating_issue_reference_id)).to eq true
      expect(serialized_decision_issue.key?(:rating_profile_date)).to eq true
      expect(serialized_decision_issue.key?(:rating_promulgation_date)).to eq true
      expect(serialized_decision_issue.key?(:subject_text)).to eq true
      expect(serialized_decision_issue.key?(:updated_at)).to eq true
    end
  end

  context "when a request issue has an edit update" do
    before do
      request_issue.update!(edited_description: "new edit")
    end

    let(:new_user_edit) { Generators::User.build }

    let!(:riu_edit) do
      RequestIssuesUpdate.create!(
        review: request_issue.decision_review,
        user: new_user_edit,
        before_request_issue_ids: [request_issue.id, request_issue_2.id],
        after_request_issue_ids: [request_issue.id, request_issue_2.id],
        edited_request_issue_ids: [request_issue.id],
        attempted_at: Time.zone.now,
        last_submitted_at: Time.zone.now,
        processed_at: Time.zone.now
      )
    end

    it "edited_by should return the user who edited the description" do
      serialized_request_issue = Api::V3::Issues::Ama::RequestIssueSerializer.new(request_issue)
        .serializable_hash[:data][:attributes]

      expect(serialized_request_issue[:edited_by_station_id]).to eq new_user_edit.station_id
      expect(serialized_request_issue[:edited_by_css_id]).to eq new_user_edit.css_id
    end
  end

  context "when a request issue has a removal update" do
    before do
      request_issue.update!(closed_status: "removed", closed_at: Time.zone.now)
    end
    let(:new_user_remove) { Generators::User.build }

    let!(:riu_remove) do
      RequestIssuesUpdate.create!(
        review: request_issue.decision_review,
        user: new_user_remove,
        before_request_issue_ids: [request_issue.id, request_issue_2.id],
        after_request_issue_ids: [request_issue_2.id],
        attempted_at: Time.zone.now,
        last_submitted_at: Time.zone.now,
        processed_at: Time.zone.now
      )
    end

    it "removed_by should return the user who removed the issue" do
      serialized_request_issue = Api::V3::Issues::Ama::RequestIssueSerializer.new(request_issue)
        .serializable_hash[:data][:attributes]

      expect(serialized_request_issue[:removed_by_station_id]).to eq new_user_remove.station_id
      expect(serialized_request_issue[:removed_by_css_id]).to eq new_user_remove.css_id
    end
  end

  context "when a request issue has a withdraw update" do
    before do
      request_issue_2.update!(closed_status: "withdrawn", closed_at: Time.zone.now)
    end
    let(:new_user_withdraw) { Generators::User.build }

    let!(:riu_remove) do
      RequestIssuesUpdate.create!(
        review: request_issue_2.decision_review,
        user: new_user_withdraw,
        before_request_issue_ids: [request_issue_2.id],
        after_request_issue_ids: [],
        withdrawn_request_issue_ids: [request_issue_2.id],
        attempted_at: Time.zone.now,
        last_submitted_at: Time.zone.now,
        processed_at: Time.zone.now
      )
    end

    it "withdrawn_by should return the user who withdrew the issue" do
      serialized_request_issue = Api::V3::Issues::Ama::RequestIssueSerializer.new(request_issue_2)
        .serializable_hash[:data][:attributes]

      expect(serialized_request_issue[:withdrawn_by_station_id]).to eq new_user_withdraw.station_id
      expect(serialized_request_issue[:withdrawn_by_css_id]).to eq new_user_withdraw.css_id
    end
  end

  context "when a new request issue is added" do
    let(:new_user_add) { Generators::User.build }
    let(:request_issue_3) do
      create(:request_issue, :with_associated_decision_issue, end_product_establishment_id: epe.id,
                                                              veteran_participant_id: vet.participant_id)
    end

    let!(:riu_add) do
      RequestIssuesUpdate.create!(
        review: request_issue_3.decision_review,
        user: new_user_add,
        before_request_issue_ids: [],
        after_request_issue_ids: [request_issue_3.id],
        attempted_at: Time.zone.now,
        last_submitted_at: Time.zone.now,
        processed_at: Time.zone.now
      )
    end

    it "added_by should return the user who added the issue via update" do
      serialized_request_issue = Api::V3::Issues::Ama::RequestIssueSerializer.new(request_issue_3)
        .serializable_hash[:data][:attributes]

      expect(serialized_request_issue[:added_by_station_id]).to eq new_user_add.station_id
      expect(serialized_request_issue[:added_by_css_id]).to eq new_user_add.css_id
      expect(serialized_request_issue[:added_by_css_id]).to_not eq user.css_id
    end
  end

  describe "converting to UTC" do
    let(:decision_issue) { create(:decision_issue, rating_profile_date: rating_profile_date) }
    let(:request_issue) { create(:request_issue, decision_issues: [decision_issue]) }
    let(:serialized_hash) { described_class.new(request_issue).serializable_hash }
    let(:serialized_decision_issue) { serialized_hash[:data][:attributes][:decision_issues].first }

    context "when rating_profile_date is present" do
      let(:rating_profile_date) { "2023-07-31T12:34:56Z" }

      it "converts the rating_profile_date to UTC" do
        expect(serialized_decision_issue[:rating_profile_date]).to eq(Time.parse(rating_profile_date).utc)
      end
    end

    context "when rating_profile_date is blank" do
      let(:rating_profile_date) { "" }

      it "sets the rating_profile_date to nil" do
        expect(serialized_decision_issue[:rating_profile_date]).to be_nil
      end
    end

    context "when rating_profile_date is spaces" do
      let(:rating_profile_date) { "   " }

      it "sets the rating_profile_date to nil" do
        expect(serialized_decision_issue[:rating_profile_date]).to be_nil
      end
    end

    context "when rating_profile_date is nil" do
      let(:rating_profile_date) { nil }

      it "sets the rating_profile_date to nil" do
        expect(serialized_decision_issue[:rating_profile_date]).to be_nil
      end
    end

    context "when rating_profile_date is DateTime" do
      let(:rating_profile_date) { DateTime.new(2024, 7, 31, 14, 0, 0, "-04:00") }

      it "converts the rating_profile_date to UTC" do
        expect(serialized_decision_issue[:rating_profile_date]).to eq(rating_profile_date.utc)
      end
    end

    context "bidirectional converting" do
      let(:rating_profile_date) { DateTime.new(2024, 7, 31, 14, 0, 0, "-04:00") }
      it "converts the rating_profile_date to UTC" do
        time_zone = "Eastern Time (US & Canada)"
        localized_time = serialized_decision_issue[:rating_profile_date].in_time_zone(time_zone)
        expect(localized_time.to_datetime).to eq(rating_profile_date)
      end
    end

    context "when rating_profile_date is invalid" do
      let(:rating_profile_date) { "invalid-date" }

      before do
        allow(described_class).to receive(:format_rating_profile_date).and_return(rating_profile_date)
      end

      it "returns the rating_profile_date as string" do
        expect(serialized_decision_issue[:rating_profile_date]).to eq(rating_profile_date)
      end
    end
  end
end
