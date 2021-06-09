# frozen_string_literal: true

describe HearingRequestDocket, :all_dbs do
  describe "#age_of_n_oldest_genpop_priority_appeals" do
    let(:judge_user) { create(:user, last_login_at: Time.zone.now) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: judge_user.css_id) }

    subject { HearingRequestDocket.new.age_of_n_oldest_genpop_priority_appeals(10) }

    it "only returns priority, distributable, hearing docket appeals that match the following conditions:
        where the most recent held hearing was not tied to an active judge
        OR
        appeals that have no hearings at all
        appeals that have no hearings with disposition held" do
      another_inactive_judge = create(:user, last_login_at: 70.days.ago)
      JudgeTeam.create_for_judge(another_inactive_judge)
      create_appeals_that_should_not_be_returned_by_query
      # base conditions = priority, distributable, hearing docket
      first_appeal = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_inactive_judge
      second_appeal = matching_all_base_conditions_with_no_hearings
      third_appeal = matching_all_base_conditions_with_no_held_hearings
      fourth_appeal = matching_all_base_conditions_with_most_recent_hearing_tied_to_other_active_judge_but_not_held
      fifth_appeal = matching_all_conditions_except_not_tied_to_active_judge
      sixth_appeal = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_active_judge
      # This one below should never happen, but is included for completeness
      seventh_appeal = matching_all_base_conditions_with_most_recent_held_hearing_not_tied_to_any_judge

      result = [first_appeal, second_appeal, third_appeal, fourth_appeal, fifth_appeal, sixth_appeal, seventh_appeal].map(&:ready_for_distribution_at).map(&:to_s)

      # For some reason, in Circle CI, the datetimes are not matching exactly to the millisecond
      expect(subject.map(&:to_s)).to match_array(result)
    end
  end

  describe "#distribute_appeals" do
    let(:distribution_judge) { create(:user, last_login_at: Time.zone.now) }
    let!(:vacols_judge) { create(:staff, :judge_role, sdomainid: distribution_judge.css_id) }
    let!(:distribution) { Distribution.create!(judge: distribution_judge) }

    context "nonpriority appeals and not_genpop" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: false, limit: 10, genpop: "not_genpop"
        )
      end

      it "only distributes nonpriority, distributable, hearing docket cases
          where the most recent held hearing is tied to the distribution judge" do
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge

        tasks = subject
        expect(tasks.length).to eq(0)
        expect(distribution.distributed_cases.length).to eq(0)
      end
    end

    context "priority appeals and not_genpop" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: true, limit: 10, genpop: "not_genpop"
        )
      end

      it "only distributes priority, distributable, hearing docket cases
          where the most recent held hearing is tied to the distribution judge" do
        # appeals that should not be returned
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        matching_all_base_conditions_with_most_recent_hearing_tied_to_other_active_judge_but_not_held
        matching_all_base_conditions_with_most_recent_hearing_tied_to_distribution_judge_but_not_held
        matching_all_base_conditions_with_most_recent_held_hearing_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_other_active_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge

        tasks = subject

        expect(tasks.length).to eq(0)
        expect(distribution.distributed_cases.length).to eq(0)
      end
    end

    context "priority appeals and genpop 'any'" do
      let(:limit) { 10 }

      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: true, limit: limit, genpop: "any"
        )
      end

      it "only distributes priority, distributable, hearing docket cases
          that are either genpop or not genpop" do
        not_tied = create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        tied = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        other_judge = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_active_judge

        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge

        tasks = subject

        expect(tasks.length).to eq(3)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq true
        expect(tasks.first.genpop_query).to eq "any"
        expect(tasks.second.genpop).to eq true
        expect(tasks.second.genpop_query).to eq "any"
        expect(distribution.distributed_cases.length).to eq(3)
        expect(distribution_judge.reload.tasks.map(&:appeal)).to match_array([tied, not_tied, other_judge])
      end

      context "when the limit is one" do
        let(:limit) { 1 }

        it "only distributes priority, distributable, hearing docket cases
          that are either genpop or not genpop" do
          not_tied = create_priority_distributable_hearing_appeal_not_tied_to_any_judge
          not_tied.tasks.find_by(type: DistributionTask.name).update(assigned_at: 1.month.ago)
          not_tied.reload
          matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
          tasks = subject

          expect(tasks.length).to eq(1)
          expect(tasks.first.class).to eq(DistributedCase)
          expect(tasks.first.genpop).to eq true
          expect(tasks.first.genpop_query).to eq "any"
          expect(distribution.distributed_cases.length).to eq(1)
          expect(distribution_judge.reload.tasks.map(&:appeal)).to match_array([not_tied])
        end
      end
    end

    context "nonpriority appeals and genpop 'any'" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: false, limit: 10, genpop: "any"
        )
      end

      it "only distributes nonpriority, distributable, hearing docket cases
          that are either genpop or not genpop" do
        create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        tied = create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        not_tied = create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        no_held_hearings = non_priority_with_no_held_hearings
        no_hearings = non_priority_with_no_hearings
        tasks = subject

        expect(tasks.length).to eq(4)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq true
        expect(tasks.first.genpop_query).to eq "any"
        expect(tasks.second.genpop).to eq true
        expect(tasks.second.genpop_query).to eq "any"
        expect(distribution.distributed_cases.length).to eq(4)
        expect(distribution_judge.reload.tasks.map(&:appeal))
          .to match_array([tied, not_tied, no_held_hearings, no_hearings])
      end
    end

    context "priority appeals and only_genpop" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: true, limit: 10, genpop: "only_genpop"
        )
      end

      it "only distributes priority, distributable, hearing docket, genpop cases" do
        appeal = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_inactive_judge
        no_held_hearings = matching_all_base_conditions_with_no_held_hearings
        no_hearings = matching_all_base_conditions_with_no_hearings
        hearing_for_different_judge = matching_all_conditions_except_not_tied_to_active_judge
        no_judge_for_hearing = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_active_judge

        create_appeals_that_should_not_be_returned_by_query
        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge

        tasks = subject

        expect(tasks.length).to eq(5)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq true
        expect(tasks.first.genpop_query).to eq "only_genpop"
        expect(distribution.distributed_cases.length).to eq(5)
        expect(distribution_judge.reload.tasks.map(&:appeal))
          .to match_array([appeal, no_held_hearings, no_hearings, hearing_for_different_judge, no_judge_for_hearing])
      end
    end

    context "nonpriority appeals and only_genpop" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: false, limit: 10, genpop: "only_genpop"
        )
      end

      it "only distributes nonpriority, distributable, hearing docket, genpop cases" do
        create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        
        non_genpop_appeal = create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        appeal = create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        no_held_hearings = non_priority_with_no_held_hearings
        no_hearings = non_priority_with_no_hearings

        tasks = subject

        expect(tasks.length).to eq(4)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.map(&:genpop).uniq).to eq [true]
        expect(tasks.map(&:genpop_query).uniq).to eq ["only_genpop"]
        expect(distribution.distributed_cases.length).to eq(4)
        expect(distribution_judge.reload.tasks.map(&:appeal))
          .to match_array([non_genpop_appeal, appeal, no_held_hearings, no_hearings])
      end
    end

    context "when an appeal aleady has a distribution" do
      subject do
        HearingRequestDocket.new.distribute_appeals(distribution, priority: false, limit: 10, genpop: "any")
      end

      it "does not fail, renames conflicting already distributed appeals, and distributes the legitimate appeals" do
        number_of_already_distributed_appeals = 1
        total_number_of_appeals = 10
        total_number_of_appeals.times { create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge }

        previous_distribution_judge = create(:user, last_login_at: Time.zone.now)
        create(:staff, :judge_role, sdomainid: previous_distribution_judge.css_id)
        previous_distribution = Distribution.create!(judge: previous_distribution_judge)
        HearingRequestDocket.new.distribute_appeals(previous_distribution,
                                                    priority: false,
                                                    limit: number_of_already_distributed_appeals,
                                                    genpop: "any")
        distributed_appeals = DistributionTask.closed.take(number_of_already_distributed_appeals).map(&:appeal)
        distributed_appeals.each do |distributed_appeal|
          DistributionTask.create!(appeal: distributed_appeal, parent: distributed_appeal.root_task)
        end

        expect(Raven).to receive(:capture_message).once

        subject

        expect(DistributionTask.open.count).to eq(0)
        distributed_cases = DistributedCase.where(distribution: distribution)
        expect(distributed_cases.count).to eq(total_number_of_appeals)
        expect(
          distributed_cases.where(case_id: distributed_appeals.map(&:uuid)).count
        ).to eq(number_of_already_distributed_appeals)
        expect(
          DistributedCase.where("case_id LIKE ?", "#{distributed_appeals.first.uuid}-redistributed-%").count
        ).to eq 1
      end
    end
  end

  describe "#count" do
    context "priority and readiness for distribution not specified" do
      it "returns all hearing docket appeals" do
        matching_all_conditions_except_priority_and_ready_for_distribution
        non_priority_with_no_held_hearings
        create_priority_distributable_hearing_appeal_not_tied_to_any_judge

        expect(HearingRequestDocket.new.count).to eq 3
      end
    end

    context "priority: true and ready: true" do
      it "only returns hearing docket appeals that are priority and ready for distribution" do
        matching_all_conditions_except_priority_and_ready_for_distribution
        non_priority_with_no_held_hearings
        create_priority_distributable_hearing_appeal_not_tied_to_any_judge

        expect(HearingRequestDocket.new.count(priority: true, ready: true)).to eq 1
      end
    end
  end

  private

  def create_appeals_that_should_not_be_returned_by_query
    matching_all_conditions_except_priority
    matching_all_conditions_except_ready_for_distribution
    matching_all_conditions_except_priority_and_ready_for_distribution
    matching_only_priority_and_ready_for_distribution
  end

  def matching_all_base_conditions_with_no_hearings
    create(:appeal,
           :advanced_on_docket_due_to_age,
           :ready_for_distribution,
           docket_type: Constants.AMA_DOCKETS.hearing)
  end

  def non_priority_with_no_hearings
    create(:appeal,
           :denied_advance_on_docket,
           :ready_for_distribution,
           docket_type: Constants.AMA_DOCKETS.hearing)
  end

  def matching_all_base_conditions_with_no_held_hearings
    appeal = create(:appeal,
                    :advanced_on_docket_due_to_age,
                    :ready_for_distribution,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "no_show", appeal: appeal)
    appeal
  end

  def non_priority_with_no_held_hearings
    appeal = create(:appeal,
                    :denied_advance_on_docket,
                    :ready_for_distribution,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "no_show", appeal: appeal)
    appeal
  end

  def matching_all_conditions_except_not_tied_to_active_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    hearing = create(:hearing,
                     judge: nil,
                     disposition: "held",
                     appeal: appeal)
    hearing.update(judge: active_judge)
    appeal
  end

  def matching_all_conditions_except_priority
    appeal = create(:appeal,
                    :denied_advance_on_docket,
                    :ready_for_distribution,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
    appeal = create(:appeal,
                    :inapplicable_aod_motion,
                    :ready_for_distribution,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
    appeal = create(:appeal,
                    :ready_for_distribution,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
  end

  def matching_all_conditions_except_ready_for_distribution
    appeal = create(:appeal,
                    :advanced_on_docket_due_to_age,
                    :with_post_intake_tasks,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
  end

  def matching_all_conditions_except_priority_and_ready_for_distribution
    appeal = create(:appeal,
                    :with_post_intake_tasks,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
  end

  def matching_only_priority_and_ready_for_distribution
    create(:appeal,
           :advanced_on_docket_due_to_age,
           :with_post_intake_tasks,
           docket_type: Constants.AMA_DOCKETS.direct_review)
  end

  def matching_all_base_conditions_with_most_recent_held_hearing_tied_to_inactive_judge
    inactive_judge = create(:user, last_login_at: 70.days.ago)
    JudgeTeam.create_for_judge(inactive_judge)
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, transcript_sent_date: 1.day.ago)
    hearing.update(judge: inactive_judge)
    appeal
  end

  def create_priority_distributable_hearing_appeal_not_tied_to_any_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal)
    appeal
  end

  def create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :denied_advance_on_docket,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: distribution_judge)

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

  def matching_all_base_conditions_with_most_recent_held_hearing_tied_to_active_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: active_judge)

    not_tied = create(:hearing_day, scheduled_for: 2.days.ago)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: not_tied)
    appeal
  end

  def matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: distribution_judge)

    not_tied = create(:hearing_day, scheduled_for: 2.days.ago)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: not_tied)
    appeal
  end

  def matching_all_base_conditions_with_most_recent_held_hearing_not_tied_to_any_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    most_recent = create(:hearing_day, scheduled_for: 3.days.ago)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)

    tied_hearing_day = create(:hearing_day, scheduled_for: 4.days.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: tied_hearing_day)
    hearing.update(judge: active_judge)

    appeal
  end

  def matching_all_base_conditions_with_most_recent_hearing_tied_to_other_active_judge_but_not_held
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "cancelled", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: active_judge)

    older_hearing_day = create(:hearing_day, scheduled_for: 2.days.ago)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: older_hearing_day)

    appeal
  end

  def matching_all_base_conditions_with_most_recent_hearing_tied_to_distribution_judge_but_not_held
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "cancelled", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: distribution_judge)

    older_hearing_day = create(:hearing_day, scheduled_for: 2.days.ago)
    create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: older_hearing_day)

    appeal
  end

  def matching_all_base_conditions_with_most_recent_held_hearing_tied_to_other_active_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent_hearing_day = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent_hearing_day)
    hearing.update(judge: active_judge)

    older_hearing_day = create(:hearing_day, scheduled_for: 2.days.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: older_hearing_day)
    hearing.update(judge: distribution_judge)

    appeal
  end

  def active_judge
    active_judge = create(:user, last_login_at: Time.zone.now)
    JudgeTeam.create_for_judge(active_judge)
    active_judge
  end
end
