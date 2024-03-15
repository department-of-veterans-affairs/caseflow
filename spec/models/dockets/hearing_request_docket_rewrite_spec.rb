# frozen_string_literal: true

describe HearingRequestDocket, :postgres do
  before do
    # Uncomment this line once the seed is removed from rails_helper.rb
    # Seeds::CaseDistributionLevers.new.seed!
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
  end

  context "#ready_priority_appeals" do
    let!(:ready_priority_appeal) { create_ready_aod_appeal }
    let!(:ready_nonpriority_appeal) { create_ready_nonpriority_appeal }
    let!(:not_ready_priority_appeal) { create_not_ready_aod_appeal }

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

        subject { HearingRequestDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(requesting_judge, 3) }

        it "returns the receipt_date field of the oldest hearing nonpriority appeals ready for distribution" do
          expect(subject).to match_array(
            [ready_nonpriority_appeal_tied_to_judge.receipt_date,
             ready_nonpriority_appeal_tied_to_excluded_judge.receipt_date,
             ready_nonpriority_appeal_hearing_cancelled.receipt_date]
          )
        end
      end

      context "without exclude from affinity set" do
        subject { HearingRequestDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(requesting_judge, 3) }

        it "returns the receipt_date field of the oldest hearing nonpriority appeals ready for distribution" do
          expect(subject).to match_array([ready_nonpriority_appeal_hearing_cancelled.receipt_date])
        end
      end
    end
  end

  context "#genpop_priority_count" do
  end

  context "#limit_genpop_appeals" do
  end

  context "#limit_only_genpop_appeals" do
  end

  context "#distribute_appeals" do
  end

  def create_ready_aod_appeal(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :advanced_on_docket_due_to_age,
      :with_post_intake_tasks,
      :held_hearing_and_ready_to_distribute,
      tied_judge: tied_judge || create(:user, :judge, :with_vacols_judge_record)
    )
    Timecop.return
    appeal
  end

  def create_ready_nonpriority_appeal(tied_judge: nil, created_date: 1.year.ago)
    Timecop.travel(created_date)
    appeal = create(
      :appeal,
      :hearing_docket,
      :with_post_intake_tasks,
      :held_hearing_and_ready_to_distribute,
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
    Timecop.return
    appeal
  end
end
