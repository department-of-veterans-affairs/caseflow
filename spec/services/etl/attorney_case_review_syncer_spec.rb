# frozen_string_literal: true

describe ETL::AttorneyCaseReviewSyncer, :etl, :all_dbs do
  let(:attorney) { create(:user) }
  let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney.css_id) }

  let(:judge) { create(:user, station_id: User::BOARD_STATION_ID) }
  let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge.css_id) }

  let!(:attorney_case_review) do
    create(:attorney_case_review, attorney: attorney, reviewing_judge: judge, task_id: task_id)
  end

  # rubocop:disable Metrics/AbcSize
  def expect_denormalized_users(etl_acr)
    expect(etl_acr.attorney_css_id).to eq(attorney.css_id)
    expect(etl_acr.attorney_full_name).to eq(attorney.full_name)
    expect(etl_acr.attorney_sattyid).to eq(vacols_atty.sattyid)
    expect(etl_acr.reviewing_judge_css_id).to eq(judge.css_id)
    expect(etl_acr.reviewing_judge_full_name).to eq(judge.full_name)
    expect(etl_acr.reviewing_judge_sattyid).to eq(vacols_judge.sattyid)
  end
  # rubocop:enable Metrics/AbcSize

  describe "#call" do
    before do
      CachedUser.sync_from_vacols
    end

    subject { described_class.new.call }

    context "LegacyAppeal" do
      let(:task_id) { "#{appeal.vacols_id}-2019-12-17" }
      let(:appeal) { create(:legacy_appeal) }

      it "denormalizes Appeal, Attorney and Reviewing Judge" do
        expect(ETL::AttorneyCaseReview.count).to eq(0)

        subject

        expect(ETL::AttorneyCaseReview.count).to eq(1)

        etl_acr = ETL::AttorneyCaseReview.first

        expect(etl_acr.appeal_id).to eq(appeal.id)
        expect(etl_acr.appeal_type).to eq("LegacyAppeal")
        expect(etl_acr.vacols_id).to eq(appeal.vacols_id)
        expect_denormalized_users(etl_acr)
      end
    end

    context "AMA Appeal" do
      let(:task_id) { create(:ama_attorney_task, appeal: appeal).id }
      let(:appeal) { create(:appeal) }

      it "denormalizes Appeal, Attorney and Reviewing Judge" do
        expect(ETL::AttorneyCaseReview.count).to eq(0)

        subject

        expect(ETL::AttorneyCaseReview.count).to eq(1)

        etl_acr = ETL::AttorneyCaseReview.first

        expect(etl_acr.appeal_id).to eq(appeal.id)
        expect(etl_acr.appeal_type).to eq("Appeal")
        expect(etl_acr.vacols_id).to be_nil
        expect_denormalized_users(etl_acr)
      end
    end
  end
end
