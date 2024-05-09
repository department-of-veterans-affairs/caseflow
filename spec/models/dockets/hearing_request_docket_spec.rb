# frozen_string_literal: true

describe HearingRequestDocket, :postgres do
  before do
    # Uncomment this line once the seed is removed from rails_helper.rb
    # Seeds::CaseDistributionLevers.new.seed!
    FeatureToggle.enable!(:acd_distribute_by_docket_date)

    # these were the defaut values at time of writing tests but can change over time, so ensure they are set
    # back to what the tests were originally written for
    CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days).update!(value: "60")
    CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days).update!(value: "14")
  end

  context "#ready_priority_appeals" do
    let!(:ready_priority_appeal) { create_ready_aod_appeal }
    let!(:ready_nonpriority_appeal) { create_ready_nonpriority_appeal }
    let!(:not_ready_priority_appeal) { create_not_ready_aod_appeal }
    let!(:not_ready_cavc_appeal) { create_not_ready_cavc_appeal }

    subject { HearingRequestDocket.new.ready_priority_appeals }

    it "returns only ready priority appeals" do
      expect(subject).to match_array([ready_priority_appeal])
    end
  end

  context "#ready_nonpriority_appeals" do
    let!(:ready_priority_appeal) { create_ready_aod_appeal }
    let!(:ready_nonpriority_appeal) { create_ready_nonpriority_appeal }
    let!(:not_ready_nonpriority_appeal) { create_not_ready_nonpriority_appeal }

    subject { HearingRequestDocket.new.ready_nonpriority_appeals }

    it "returns only ready nonpriority appeals" do
      expect(subject).to match_array([ready_nonpriority_appeal])
    end
  end

  context "age_of_n methods" do
    let(:requesting_judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:excluded_judge) { create(:user, :judge, :with_vacols_judge_record) }

    let!(:ready_aod_appeal_tied_to_judge) do
      create_ready_aod_appeal(tied_judge: requesting_judge, created_date: 7.days.ago)
    end
    let!(:ready_nonpriority_appeal_tied_to_judge) do
      create_ready_nonpriority_appeal(tied_judge: requesting_judge, created_date: 5.days.ago)
    end
    let!(:ready_aod_appeal_tied_to_excluded_judge) do
      create_ready_aod_appeal(tied_judge: excluded_judge, created_date: 3.days.ago)
    end
    let!(:ready_nonpriority_appeal_tied_to_excluded_judge) do
      create_ready_nonpriority_appeal(tied_judge: excluded_judge, created_date: 1.day.ago)
    end
    let!(:ready_aod_appeal_hearing_cancelled) do
      create_ready_aod_appeal_hearing_cancelled(created_date: 2.days.ago)
    end
    let!(:ready_nonpriority_appeal_hearing_cancelled) do
      create_ready_nonpriority_appeal_hearing_cancelled(created_date: 2.days.ago)
    end

    context "#age_of_n_oldest_priority_appeals_available_to_judge" do
      context "with exclude from affintiy set" do
        before do
          FeatureToggle.enable!(:acd_exclude_from_affinity)
          JudgeTeam.for_judge(excluded_judge).update!(exclude_appeals_from_affinity: true)
        end

        subject { HearingRequestDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(requesting_judge, 3) }

        it "returns the receipt_date field of the oldest hearing priority appeals ready for distribution" do
          expect(subject).to match_array(
            [ready_aod_appeal_tied_to_judge.receipt_date,
             ready_aod_appeal_tied_to_excluded_judge.receipt_date,
             ready_aod_appeal_hearing_cancelled.receipt_date]
          )
        end
      end

      context "without exclude from affinity set" do
        subject { HearingRequestDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(requesting_judge, 3) }

        it "returns the receipt_date field of the oldest hearing priority appeals ready for distribution" do
          expect(subject).to match_array([ready_aod_appeal_hearing_cancelled.receipt_date])
        end
      end
    end

    context "#age_of_n_oldest_nonpriority_appeals_available_to_judge" do
      context "with exclude from affinity set" do
        before do
          FeatureToggle.enable!(:acd_exclude_from_affinity)
          JudgeTeam.for_judge(excluded_judge).update!(exclude_appeals_from_affinity: true)
        end

        subject do
          HearingRequestDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(requesting_judge, 3)
        end

        it "returns the receipt_date field of the oldest hearing nonpriority appeals ready for distribution" do
          expect(subject).to match_array(
            [ready_nonpriority_appeal_tied_to_judge.receipt_date,
             ready_nonpriority_appeal_tied_to_excluded_judge.receipt_date,
             ready_nonpriority_appeal_hearing_cancelled.receipt_date]
          )
        end
      end

      context "without exclude from affinity set" do
        subject do
          HearingRequestDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(requesting_judge, 3)
        end

        it "returns the receipt_date field of the oldest hearing nonpriority appeals ready for distribution" do
          expect(subject).to match_array([ready_nonpriority_appeal_hearing_cancelled.receipt_date])
        end
      end
    end
  end

  context "when the distribution contains Specialty Case Team appeals" do
    subject do
      HearingRequestDocket.new.distribute_appeals(distribution, priority: false, limit: limit, genpop: "any")
    end

    let(:distribution_judge) { create(:user, last_login_at: Time.zone.now) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: distribution_judge.css_id) }
    let!(:distribution) { Distribution.create!(judge: distribution_judge) }

    let(:limit) { 15 }

    let!(:vha_appeals) do
      (1..5).map { create_nonpriority_distributable_vha_hearing_appeal_not_tied_to_any_judge }
    end

    let!(:non_vha_appeals) do
      (1..20).map { create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge }
    end

    context "when specialty_case_team_distribution feature toggle is enabled" do
      before do
        FeatureToggle.enable!(:specialty_case_team_distribution)
      end
      after do
        FeatureToggle.disable!(:specialty_case_team_distribution)
      end

      it "does not fail, renames conflicting already distributed appeals, and distributes the legitimate appeals" do
        subject

        expect(DistributionTask.open.count).to eq(5)
        distributed_cases = DistributedCase.where(distribution: distribution)
        expect(distributed_cases.count).to eq(20)
        expect(distributed_cases.count(&:sct_appeal)).to eq(5)
      end
    end

    context "when specialty_case_team_distribution feature toggle is disabled" do
      before do
        FeatureToggle.disable!(:specialty_case_team_distribution)
      end

      it "does not fail, renames conflicting already distributed appeals, and distributes the legitimate appeals" do
        subject

        # It should only distribute 15 appeals due to the limit so 10 should remain in the ready to distribute state
        expect(DistributionTask.open.count).to eq(10)
        distributed_cases = DistributedCase.where(distribution: distribution)
        expect(distributed_cases.count).to eq(15)
        expect(distributed_cases.count(&:sct_appeal)).to eq(0)
      end
    end
  end

  context "#genpop_priority_count" do
    let(:excluded_judge) { create(:user, :judge, :with_vacols_judge_record) }
    let(:ineligible_judge) { create(:user, :judge, :inactive) }

    let!(:ready_tied_aod_appeal) do
      create_ready_aod_appeal(created_date: 7.days.ago)
    end
    let!(:ready_tied_nonpriority_appeal) do
      create_ready_nonpriority_appeal(created_date: 7.days.ago)
    end
    let!(:ready_tied_to_excluded_aod_appeal) do
      create_ready_aod_appeal(tied_judge: excluded_judge, created_date: 7.days.ago)
    end
    let!(:ready_tied_to_excluded_nonpriority_appeal) do
      create_ready_nonpriority_appeal(tied_judge: excluded_judge, created_date: 7.days.ago)
    end
    let!(:ready_tied_to_ineligible_aod_appeal) do
      create_ready_aod_appeal(tied_judge: ineligible_judge, created_date: 7.days.ago)
    end
    let!(:ready_tied_to_ineligible_nonpriority_appeal) do
      create_ready_nonpriority_appeal(tied_judge: ineligible_judge, created_date: 7.days.ago)
    end
    let!(:ready_aod_appeal_hearing_cancelled) do
      create_ready_aod_appeal_hearing_cancelled(created_date: 7.days.ago)
    end
    let!(:ready_nonpriority_appeal_hearing_cancelled) do
      create_ready_nonpriority_appeal_hearing_cancelled(created_date: 7.days.ago)
    end

    subject { HearingRequestDocket.new.genpop_priority_count }

    context "with exclude from affinity enabled" do
      before do
        FeatureToggle.enable!(:acd_exclude_from_affinity)
        JudgeTeam.for_judge(excluded_judge).update!(exclude_appeals_from_affinity: true)
      end

      it { is_expected.to eq 2 }
    end

    context "with exclude from affinity disabled" do
      it { is_expected.to eq 1 }
    end

    context "with ineligible judges enabled" do
      before do
        FeatureToggle.enable!(:acd_cases_tied_to_judges_no_longer_with_board)
        IneligibleJudgesJob.new.perform_now
      end

      it { is_expected.to eq 2 }
    end

    context "with ineligible judges disabled" do
      before { IneligibleJudgesJob.new.perform_now }

      it { is_expected.to eq 1 }
    end
  end

  context "limit appeals class methods" do
    let(:appeal_1_week_old) { create_ready_aod_appeal(created_date: 1.week.ago) }
    let(:appeal_4_weeks_old) { create_ready_aod_appeal(created_date: 4.weeks.ago) }
    let(:appeal_2_weeks_old) { create_ready_nonpriority_appeal(created_date: 2.weeks.ago) }
    let(:appeal_3_weeks_old) { create_ready_nonpriority_appeal(created_date: 3.weeks.ago) }
    let!(:array_1) { [appeal_1_week_old, appeal_4_weeks_old] }
    let!(:array_2) { [appeal_2_weeks_old, appeal_3_weeks_old] }

    context "#limit_genpop_appeals" do
      subject { HearingRequestDocket.limit_genpop_appeals([array_1, array_2], 2) }

      it "correctly applies limit" do
        # This method does not flatten them, only removes the newest appeals to the limit from the 2d array
        expect(subject).to match_array([[appeal_4_weeks_old], [appeal_3_weeks_old]])
      end
    end

    context "#limit_only_genpop_appeals" do
      subject { HearingRequestDocket.limit_only_genpop_appeals([*array_1, *array_2], 2) }

      context "with exclude from affinity enabled" do
        before { FeatureToggle.enable!(:acd_exclude_from_affinity) }

        it "correctly flattens the arrays and applies limit" do
          result = HearingRequestDocket.limit_only_genpop_appeals([array_1, array_2], 2)
          expect(result).to match_array([appeal_4_weeks_old, appeal_3_weeks_old])
        end

        it "handles empty arrays" do
          result = HearingRequestDocket.limit_only_genpop_appeals([array_1, []], 2)
          expect(result).to match_array([appeal_1_week_old, appeal_4_weeks_old])
        end
      end

      it "correctly flattens the arrays and applies limit" do
        expect(subject).to match_array([appeal_4_weeks_old, appeal_3_weeks_old])
      end
    end
  end

  context "#distribute_appeals" do
    let!(:requesting_judge_no_attorneys) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:requesting_judge_with_attorneys) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:other_judge) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:excluded_judge) { create(:user, :judge, :with_vacols_judge_record) }
    let!(:ineligible_judge) { create(:user, :judge, :with_vacols_judge_record, :inactive) }

    let!(:requesting_judge_attorney) { create(:user, :with_vacols_attorney_record) }

    let(:priority) { false }
    let!(:distribution) { Distribution.create!(judge: requesting_judge_no_attorneys) }

    before do
      # Makes this judge team follow the batch_size calculation
      JudgeTeam.for_judge(requesting_judge_with_attorneys).add_user(requesting_judge_attorney)
      # This feature toggle being off will cause the query to not distribute tied cases
      FeatureToggle.enable!(:acd_exclude_from_affinity)
    end

    subject do
      HearingRequestDocket.new.distribute_appeals(
        distribution, priority: priority, genpop: "only_genpop", limit: 15, style: "request"
      )
    end

    context "ama_hearing_case_affinity_days" do
      let!(:ready_nonpriority_tied_to_requesting_judge_in_window) do
        create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 15.days.ago)
      end
      let!(:ready_nonpriority_tied_to_requesting_judge_out_of_window_45_days) do
        create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 45.days.ago)
      end
      let!(:ready_nonpriority_tied_to_requesting_judge_out_of_window_100_days) do
        create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 100.days.ago)
      end
      let!(:ready_nonpriority_tied_to_other_judge_in_window) do
        create_ready_nonpriority_appeal(tied_judge: other_judge, created_date: 15.days.ago)
      end
      let!(:ready_nonpriority_tied_to_other_judge_out_of_window_45_days) do
        create_ready_nonpriority_appeal(tied_judge: other_judge, created_date: 45.days.ago)
      end
      let!(:ready_nonpriority_tied_to_other_judge_out_of_window_100_days) do
        create_ready_nonpriority_appeal(tied_judge: other_judge, created_date: 100.days.ago)
      end
      let!(:ready_nonpriority_hearing_cancelled) do
        create_ready_nonpriority_appeal_hearing_cancelled(created_date: 10.days.ago)
      end

      context "lever is set to omit" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
            .update!(value: "omit")
        end

        it "distributes all appeals regardless of tied judge" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_45_days.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_100_days.uuid,
             ready_nonpriority_tied_to_other_judge_in_window.uuid,
             ready_nonpriority_tied_to_other_judge_out_of_window_45_days.uuid,
             ready_nonpriority_tied_to_other_judge_out_of_window_100_days.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end

      context "lever is set to a numeric value (30)" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
            .update!(value: "30")
        end

        it "distributes appeals that exceed affinity value or are tied to the requesting judge or are genpop" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_45_days.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_100_days.uuid,
             ready_nonpriority_tied_to_other_judge_out_of_window_45_days.uuid,
             ready_nonpriority_tied_to_other_judge_out_of_window_100_days.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end

      context "lever is set to a numeric value (90)" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
            .update!(value: "90")
        end

        it "distributes appeals that exceed affinity value or are tied to the requesting judge or are genpop" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_45_days.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_100_days.uuid,
             ready_nonpriority_tied_to_other_judge_out_of_window_100_days.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end

      context "lever is set to infinite" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
            .update!(value: "infinite")
        end

        it "distributes only genpop appeals or appeals tied to the requesting judge" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_45_days.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window_100_days.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end
    end

    # all of these are currently failing
    context "ama_hearing_case_aod_affinity_days" do
      let!(:ready_aod_tied_to_requesting_judge_in_window) do
        create_ready_aod_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 10.days.ago)
      end
      let!(:ready_aod_tied_to_requesting_judge_out_of_window_20_days) do
        create_ready_aod_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 20.days.ago)
      end
      let!(:ready_aod_tied_to_requesting_judge_out_of_window_40_days) do
        create_ready_aod_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 40.days.ago)
      end
      let!(:ready_aod_tied_to_other_judge_in_window) do
        create_ready_aod_appeal(tied_judge: other_judge, created_date: 10.days.ago)
      end
      let!(:ready_aod_tied_to_other_judge_out_of_window_20_days) do
        create_ready_aod_appeal(tied_judge: other_judge, created_date: 20.days.ago)
      end
      let!(:ready_aod_tied_to_other_judge_out_of_window_40_days) do
        create_ready_aod_appeal(tied_judge: other_judge, created_date: 40.days.ago)
      end
      let!(:ready_aod_hearing_cancelled) do
        create_ready_aod_appeal_hearing_cancelled(created_date: 10.days.ago)
      end

      let(:priority) { true }

      context "lever is set to omit" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days)
            .update!(value: "omit")
        end

        it "distributes all appeals regardless of tied judge" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_aod_tied_to_requesting_judge_in_window.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_40_days.uuid,
             ready_aod_tied_to_other_judge_in_window.uuid,
             ready_aod_tied_to_other_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_other_judge_out_of_window_40_days.uuid,
             ready_aod_hearing_cancelled.uuid]
          )
        end
      end

      context "lever is set to a numeric value (15)" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days)
            .update!(value: "15")
        end

        it "distributes appeals that exceed affinity value or are tied to the requesting judge or are genpop" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_aod_tied_to_requesting_judge_in_window.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_40_days.uuid,
             ready_aod_tied_to_other_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_other_judge_out_of_window_40_days.uuid,
             ready_aod_hearing_cancelled.uuid]
          )
        end
      end

      context "lever is set to a numeric value (30)" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days)
            .update!(value: "30")
        end

        it "distributes appeals that exceed affinity value or are tied to the requesting judge or are genpop" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_aod_tied_to_requesting_judge_in_window.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_40_days.uuid,
             ready_aod_tied_to_other_judge_out_of_window_40_days.uuid,
             ready_aod_hearing_cancelled.uuid]
          )
        end
      end

      context "lever is set to infinite" do
        before do
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days)
            .update!(value: "infinite")
        end

        it "distributes only genpop appeals or appeals tied to the requesting judge" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_aod_tied_to_requesting_judge_in_window.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_40_days.uuid,
             ready_aod_hearing_cancelled.uuid]
          )
        end
      end
    end

    # there is no test currently for "toggle off" because the toggle off is causing errors during distribution
    context "acd_exclude_from_affinity" do
      context "toggle on" do
        before do
          FeatureToggle.enable!(:acd_exclude_from_affinity)
          JudgeTeam.for_judge(excluded_judge).update!(exclude_appeals_from_affinity: true)
          CaseDistributionLever
            .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days)
            .update!(value: "30")
        end

        let!(:ready_nonpriority_tied_to_requesting_judge_in_window) do
          create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 15.days.ago)
        end
        let!(:ready_nonpriority_tied_to_requesting_judge_out_of_window) do
          create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 45.days.ago)
        end
        let!(:ready_nonpriority_tied_to_excluded_judge_in_window) do
          create_ready_nonpriority_appeal(tied_judge: excluded_judge, created_date: 15.days.ago)
        end
        let!(:ready_nonpriority_tied_to_excluded_judge_out_of_window) do
          create_ready_nonpriority_appeal(tied_judge: excluded_judge, created_date: 45.days.ago)
        end
        let!(:ready_nonpriority_hearing_cancelled) do
          create_ready_nonpriority_appeal_hearing_cancelled(created_date: 10.days.ago)
        end

        it "includes excluded judge appeals in affinity window" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window.uuid,
             ready_nonpriority_tied_to_excluded_judge_in_window.uuid,
             ready_nonpriority_tied_to_excluded_judge_out_of_window.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end
    end

    context "ineligible judge appeals" do
      before do
        CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days).update!(value: "30")
        IneligibleJudgesJob.new.perform_now
      end

      let!(:ready_nonpriority_tied_to_requesting_judge_in_window) do
        create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 15.days.ago)
      end
      let!(:ready_nonpriority_tied_to_requesting_judge_out_of_window) do
        create_ready_nonpriority_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 45.days.ago)
      end
      let!(:ready_nonpriority_tied_to_ineligible_judge_in_window) do
        create_ready_nonpriority_appeal(tied_judge: ineligible_judge, created_date: 15.days.ago)
      end
      let!(:ready_nonpriority_tied_to_ineligible_judge_out_of_window) do
        create_ready_nonpriority_appeal(tied_judge: ineligible_judge, created_date: 45.days.ago)
      end
      let!(:ready_nonpriority_hearing_cancelled) do
        create_ready_nonpriority_appeal_hearing_cancelled(created_date: 10.days.ago)
      end

      context "with toggle on" do
        before { FeatureToggle.enable!(:acd_cases_tied_to_judges_no_longer_with_board) }

        it "includes ineligible judge appeals in affinity window" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window.uuid,
             ready_nonpriority_tied_to_ineligible_judge_in_window.uuid,
             ready_nonpriority_tied_to_ineligible_judge_out_of_window.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end

      context "with toggle off" do
        before { FeatureToggle.disable!(:acd_cases_tied_to_judges_no_longer_with_board) }

        it "does not include ineligible judge appeals in affinity window" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_nonpriority_tied_to_requesting_judge_in_window.uuid,
             ready_nonpriority_tied_to_requesting_judge_out_of_window.uuid,
             ready_nonpriority_tied_to_ineligible_judge_out_of_window.uuid,
             ready_nonpriority_hearing_cancelled.uuid]
          )
        end
      end
    end

    context "with multiple levers enabled and appeals meeting each criteria" do
      # ready non-aod appeals
      let!(:ready_cavc_appeal_tied_to_requesting_judge_in_window) do
        create_ready_cavc_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 7.days.ago)
      end
      let!(:ready_cavc_appeal_tied_to_requesting_judge_out_of_window_21_days) do
        create_ready_cavc_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 21.days.ago)
      end
      let!(:ready_cavc_appeal_tied_to_other_judge_in_window) do
        create_ready_cavc_appeal(tied_judge: other_judge, created_date: 7.days.ago)
      end
      let!(:ready_cavc_appeal_tied_to_other_judge_out_of_window_21_days) do
        create_ready_cavc_appeal(tied_judge: other_judge, created_date: 21.days.ago)
      end

      # ready aod appeals
      let!(:ready_aod_tied_to_requesting_judge_in_window) do
        create_ready_aod_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 10.days.ago)
      end
      let!(:ready_aod_tied_to_requesting_judge_out_of_window_20_days) do
        create_ready_aod_appeal(tied_judge: requesting_judge_no_attorneys, created_date: 20.days.ago)
      end
      let!(:ready_aod_tied_to_other_judge_in_window) do
        create_ready_aod_appeal(tied_judge: other_judge, created_date: 10.days.ago)
      end
      let!(:ready_aod_tied_to_other_judge_out_of_window_20_days) do
        create_ready_aod_appeal(tied_judge: other_judge, created_date: 20.days.ago)
      end

      # appeal which is always genpop
      let!(:ready_aod_hearing_cancelled) do
        create_ready_aod_appeal_hearing_cancelled(created_date: 10.days.ago)
      end

      let!(:sct_ready_priority_appeal_not_tied_to_a_judge) do
        create_priority_distributable_vha_hearing_appeal_not_tied_to_any_judge
      end

      before do
        FeatureToggle.enable!(:specialty_case_team_distribution)
        CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.ama_hearing_case_affinity_days).update!(value: "30")
        CaseDistributionLever.find_by_item(Constants.DISTRIBUTION.cavc_affinity_days).update!(value: "14")
        CaseDistributionLever
          .find_by_item(Constants.DISTRIBUTION.ama_hearing_case_aod_affinity_days)
          .update!(value: "15")
      end

      context "for priority appeals" do
        let(:priority) { true }

        it "distributes appeals as expected" do
          expect(subject.map(&:case_id)).to match_array(
            [ready_cavc_appeal_tied_to_requesting_judge_in_window.uuid,
             ready_cavc_appeal_tied_to_requesting_judge_out_of_window_21_days.uuid,
             ready_cavc_appeal_tied_to_other_judge_out_of_window_21_days.uuid,
             ready_aod_tied_to_requesting_judge_in_window.uuid,
             ready_aod_tied_to_requesting_judge_out_of_window_20_days.uuid,
             ready_aod_tied_to_other_judge_out_of_window_20_days.uuid,
             ready_aod_hearing_cancelled.uuid,
             sct_ready_priority_appeal_not_tied_to_a_judge.uuid]
          )
          expect(sct_ready_priority_appeal_not_tied_to_a_judge.specialty_case_team_assign_task?).to be true
        end
      end
    end
  end

  def create_ready_aod_appeal(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :advanced_on_docket_due_to_age,
      :with_post_intake_tasks,
      :held_hearing_and_ready_to_distribute,
      :with_appeal_affinity,
      tied_judge: tied_judge || create(:user, :judge, :with_vacols_judge_record)
    )
    Timecop.return
    appeal
  end

  def create_ready_cavc_appeal(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date - 6.months)
    if tied_judge
      judge = tied_judge
      attorney = JudgeTeam.for_judge(judge)&.attorneys&.first || create(:user, :with_vacols_attorney_record)
    else
      judge = create(:user, :judge, :with_vacols_judge_record)
      attorney = create(:user, :with_vacols_attorney_record)
    end

    source_appeal = create(
      :appeal,
      :hearing_docket,
      :held_hearing,
      :tied_to_judge,
      :dispatched,
      # associated_judge and tied_judge are both required to satisfy different traits
      associated_judge: judge,
      associated_attorney: attorney,
      tied_judge: judge
    )

    Timecop.travel(6.months.from_now)
    cavc_remand = create(
      :cavc_remand,
      source_appeal: source_appeal
    )
    remand_appeal = cavc_remand.remand_appeal
    distribution_tasks = remand_appeal.tasks.select { |task| task.is_a?(DistributionTask) }
    (distribution_tasks.flat_map(&:descendants) - distribution_tasks).each(&:completed!)
    create(:appeal_affinity, appeal: remand_appeal)
    Timecop.return

    remand_appeal
  end

  def create_ready_nonpriority_appeal(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :with_post_intake_tasks,
      :held_hearing_and_ready_to_distribute,
      :with_appeal_affinity,
      tied_judge: tied_judge || create(:user, :judge, :with_vacols_judge_record)
    )
    Timecop.return
    appeal
  end

  def create_not_ready_aod_appeal(created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :advanced_on_docket_due_to_age,
      :with_post_intake_tasks
    )
    Timecop.return
    appeal
  end

  def create_not_ready_cavc_appeal(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date - 6.months)
    if tied_judge
      judge = tied_judge
      attorney = JudgeTeam.for_judge(judge)&.attorneys&.first || create(:user, :with_vacols_attorney_record)
    else
      judge = create(:user, :judge, :with_vacols_judge_record)
      attorney = create(:user, :with_vacols_attorney_record)
    end

    source_appeal = create(
      :appeal,
      :hearing_docket,
      :held_hearing,
      :tied_to_judge,
      :dispatched,
      # associated_judge and tied_judge are both required to satisfy different traits
      associated_judge: judge,
      associated_attorney: attorney,
      tied_judge: judge
    )

    Timecop.travel(6.months.from_now)
    cavc_remand = create(
      :cavc_remand,
      source_appeal: source_appeal
    )
    Timecop.return

    cavc_remand.remand_appeal
  end

  def create_not_ready_nonpriority_appeal(created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :with_post_intake_tasks
    )
    Timecop.return
    appeal
  end

  def create_ready_aod_appeal_hearing_cancelled(created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :with_post_intake_tasks,
      :advanced_on_docket_due_to_age,
      :cancelled_hearing_and_ready_to_distribute
    )
    Timecop.return
    appeal
  end

  def create_ready_nonpriority_appeal_hearing_cancelled(created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :with_post_intake_tasks,
      :cancelled_hearing_and_ready_to_distribute
    )
    appeal.tasks.find_by(type: ScheduleHearingTask.name).cancelled!
    Timecop.return
    appeal
  end

  def create_nonpriority_distributable_vha_hearing_appeal_not_tied_to_any_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :denied_advance_on_docket,
                    :with_vha_issue,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
    appeal
  end

  def create_priority_distributable_vha_hearing_appeal_not_tied_to_any_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_age,
                    :with_vha_issue,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
    appeal
  end

  def create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :denied_advance_on_docket,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
    appeal
  end
end
