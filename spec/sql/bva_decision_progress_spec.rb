# frozen_string_literal: true

require "support/database_cleaner"

describe "BVA Decision Progress report", :postgres do
  include SQLHelpers

  context "one row for each category" do
    let(:expected_report) do
      [
        { "decision_status" => "1. Not distributed", "num" => 1 },
        { "decision_status" => "2. Distributed to judge", "num" => 1 },
        { "decision_status" => "3. Assigned to attorney", "num" => 1 },
        { "decision_status" => "4. Assigned to colocated", "num" => 1 },
        { "decision_status" => "5. Decision in progress", "num" => 1 },
        { "decision_status" => "6. Decision ready for signature", "num" => 1 },
        { "decision_status" => "7. Decision signed", "num" => 1 },
        { "decision_status" => "8. Decision dispatched", "num" => 1 },
        { "decision_status" => "CANCELLED", "num" => 1 },
        { "decision_status" => "MISC", "num" => 1 },
        { "decision_status" => "ON HOLD", "num" => 1 }
      ]
    end

    let(:user) { create(:default_user) }
    let!(:not_distributed) { create(:appeal, :ready_for_distribution) }
    let!(:distributed_to_judge) { create(:appeal, :assigned_to_judge) }
    let!(:assigned_to_attorney) { create(:appeal).tap { |appeal| create(:ama_attorney_task, appeal: appeal) } }
    let!(:assigned_to_colocated) do
      create(:appeal).tap do |appeal|
        create(:ama_colocated_task, appeal: appeal, assigned_to: user)
      end
    end
    let!(:decision_in_progress) do
      create(:appeal).tap do |appeal|
        create(:ama_attorney_task, :in_progress, appeal: appeal)
      end
    end
    let!(:decision_ready_for_signature) do
      create(:appeal).tap do |appeal|
        create(:ama_judge_decision_review_task, :in_progress, appeal: appeal)
      end
    end
    let!(:decision_signed) do
      create(:appeal).tap do |appeal|
        create(:bva_dispatch_task, :in_progress, appeal: appeal)
      end
    end
    let!(:decision_dispatched) do
      create(:appeal).tap do |appeal|
        create(:bva_dispatch_task, :completed, appeal: appeal)
      end
    end
    let!(:cancelled) do
      create(:appeal).tap do |appeal|
        create(:root_task, :cancelled, appeal: appeal)
      end
    end
    let!(:on_hold) do
      create(:appeal).tap do |appeal|
        create(:timed_hold_task, appeal: appeal)
      end
    end
    let!(:misc) do
      create(:appeal).tap do |appeal|
        create(:ama_judge_dispatch_return_task, appeal: appeal)
      end
    end

    it "generates correct report" do
      expect_sql("bva-decision-progress").to eq(expected_report)
    end
  end
end
