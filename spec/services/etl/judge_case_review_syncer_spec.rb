# frozen_string_literal: true

describe ETL::JudgeCaseReviewSyncer, :etl, :all_dbs do
  let(:attorney) { create(:user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }

  let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let!(:judge_case_review) do
    create(:judge_case_review, location: :bva_dispatch, task_id: task_id, judge: judge, attorney: attorney)
  end

  let(:etl_build) { ETL::Build.create }

  # rubocop:disable Metrics/AbcSize
  def expect_denormalized_users(etl_jcr)
    expect(etl_jcr.attorney_css_id).to eq(attorney.css_id)
    expect(etl_jcr.attorney_full_name).to eq(attorney.full_name)
    expect(etl_jcr.attorney_sattyid).to eq(vacols_atty.sattyid)
    expect(etl_jcr.judge_css_id).to eq(judge.css_id)
    expect(etl_jcr.judge_full_name).to eq(judge.full_name)
    expect(etl_jcr.judge_sattyid).to eq(vacols_judge.sattyid)
  end
  # rubocop:enable Metrics/AbcSize

  describe "#call" do
    before do
      CachedUser.sync_from_vacols
      ETL::UserSyncer.new(etl_build: etl_build).call
    end

    subject { described_class.new(etl_build: etl_build).call }

    context "LegacyAppeal" do
      let(:appeal) { create(:legacy_appeal) }
      let(:task_id) { "#{appeal.vacols_id}-2019-12-17" }

      it "denormalizes Appeal, Attorney and Reviewing Judge" do
        expect(ETL::JudgeCaseReview.count).to eq(0)

        subject

        expect(ETL::JudgeCaseReview.count).to eq(1)

        etl_jcr = ETL::JudgeCaseReview.first

        expect(etl_jcr.appeal_id).to eq(appeal.id)
        expect(etl_jcr.appeal_type).to eq("LegacyAppeal")
        expect(etl_jcr.vacols_id).to eq(appeal.vacols_id)
        expect_denormalized_users(etl_jcr)
      end
    end

    context "AMA Appeal" do
      let(:appeal) { create(:appeal) }
      let(:task_id) { create(:ama_judge_decision_review_task, appeal: appeal).id }

      it "denormalizes Appeal, Attorney and Reviewing Judge" do
        expect(ETL::JudgeCaseReview.count).to eq(0)

        subject

        expect(ETL::JudgeCaseReview.count).to eq(1)

        etl_jcr = ETL::JudgeCaseReview.first

        expect(etl_jcr.appeal_id).to eq(appeal.id)
        expect(etl_jcr.appeal_type).to eq("Appeal")
        expect(etl_jcr.vacols_id).to be_nil
        expect_denormalized_users(etl_jcr)
      end
    end
  end
end
