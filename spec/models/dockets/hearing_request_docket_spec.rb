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
      create_appeals_that_should_not_be_returned_by_query

      # base conditions = priority, distributable, hearing docket
      first_appeal = matching_all_base_conditions_with_no_hearings
      second_appeal = matching_all_base_conditions_with_no_held_hearings
      third_appeal = matching_all_base_conditions_with_most_recent_hearing_tied_to_other_judge_but_not_held
      fourth_appeal = matching_all_base_conditions_with_most_recent_held_hearing_not_tied_to_any_judge

      result = [first_appeal, second_appeal, third_appeal, fourth_appeal]
        .map(&:ready_for_distribution_at).map(&:to_s)

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
          where the most recent held hearing is tied to the distribution judge
          but doesn't exceed affinity threshold" do
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge

        # This is the only one that is still considered tied (we want only non_genpop)
        appeal = create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge

        # This appeal should not be returned because it is now considered genpop
        outside_affinity = create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge_outside_affinity
        tasks = subject

        distributed_appeals = distribution_judge.reload.tasks.map(&:appeal)

        expect(tasks.length).to eq(1)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq false
        expect(tasks.first.genpop_query).to eq "not_genpop"
        expect(distribution.distributed_cases.length).to eq(1)
        expect(distribution_judge.reload.tasks.map(&:appeal)).to eq([appeal])

        # If hearing date exceeds specified days for affinity, appeal no longer tied to judge
        expect(distributed_appeals).not_to include(outside_affinity)
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
        matching_all_base_conditions_with_most_recent_hearing_tied_to_other_judge_but_not_held
        matching_all_base_conditions_with_most_recent_hearing_tied_to_distribution_judge_but_not_held
        matching_all_base_conditions_with_most_recent_held_hearing_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_other_judge

        # appeals that should be returned
        appeal = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        another = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge

        tasks = subject

        expect(tasks.length).to eq(2)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq false
        expect(tasks.first.genpop_query).to eq "not_genpop"
        expect(distribution.distributed_cases.length).to eq(2)
        expect(distribution_judge.reload.tasks.map(&:appeal)).to match_array([appeal, another])
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
        # will be included
        not_tied = create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        tied = matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        outside_affinity = matching_all_base_conditions_with_most_recent_held_hearing_outside_affinity
        expected_result = [tied, not_tied, outside_affinity]

        # won't be included
        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_judge

        tasks = subject

        expect(tasks.map(&:case_id)).to match_array(expected_result.map(&:uuid))
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq false
        expect(tasks.first.genpop_query).to eq "any"
        expect(tasks.second.genpop).to eq true
        expect(tasks.second.genpop_query).to eq "any"
        expect(distribution.distributed_cases.length).to eq(expected_result.length)
        expect(distribution_judge.reload.tasks.map(&:appeal)).to match_array(expected_result)
      end

      context "when the limit is one" do
        let(:limit) { 1 }

        it "only distributes priority, distributable, hearing docket cases
          that are either genpop or not genpop" do
          num_days = CaseDistributionLever.ama_hearing_case_affinity_days + 1
          days_ago = Time.zone.now.days_ago(num_days)

          # This one will be included
          not_tied = create_priority_distributable_hearing_appeal_not_tied_to_any_judge
          not_tied.tasks.find_by(type: DistributionTask.name).update(assigned_at: days_ago)
          not_tied.reload

          # This would have been included, except for limit
          matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge

          tasks = subject

          # We expect only as many as the limit
          expect(tasks.length).to eq(limit)
          expect(tasks.first.class).to eq(DistributedCase)
          expect(tasks.first.genpop).to eq true
          expect(tasks.first.genpop_query).to eq "any"
          expect(distribution.distributed_cases.length).to eq(limit)
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
        # won't be included
        create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        non_distributable = create_nonpriority_unblocked_hearing_appeal_within_affinity

        # will be included
        tied = create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        not_tied = create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        no_held_hearings = non_priority_with_no_held_hearings
        no_hearings = non_priority_with_no_hearings
        outside_affinity = create_nonpriority_distributable_hearing_appeal_tied_to_other_judge_outside_affinity

        expected_result = [tied, not_tied, no_held_hearings, no_hearings, outside_affinity]

        tasks = subject

        appeal_ids = tasks.map(&:case_id)
        expect(appeal_ids).to match_array(expected_result.map(&:uuid))
        expect(appeal_ids).to_not include(non_distributable.uuid)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq false
        expect(tasks.first.genpop_query).to eq "any"
        expect(tasks.second.genpop).to eq true
        expect(tasks.second.genpop_query).to eq "any"
        expect(distribution.distributed_cases.length).to eq(expected_result.length)
        expect(distribution_judge.reload.tasks.map(&:appeal))
          .to match_array(expected_result)
      end
    end

    context "priority appeals and only_genpop" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: true, limit: 10, genpop: "only_genpop"
        )
      end

      it "only distributes priority, distributable, hearing docket, genpop cases" do
        # will be included
        outside_affinity = matching_all_base_conditions_with_most_recent_held_hearing_outside_affinity
        no_held_hearings = matching_all_base_conditions_with_no_held_hearings
        no_hearings = matching_all_base_conditions_with_no_hearings

        expected_result = [outside_affinity, no_held_hearings, no_hearings]

        # won't be included
        create_appeals_that_should_not_be_returned_by_query
        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge
        create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge

        tasks = subject

        expect(tasks.length).to eq(expected_result.length)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.first.genpop).to eq true
        expect(tasks.first.genpop_query).to eq "only_genpop"
        expect(distribution.distributed_cases.length).to eq(expected_result.length)
        expect(distribution_judge.reload.tasks.map(&:appeal))
          .to match_array(expected_result)
      end
    end

    context "nonpriority appeals and only_genpop" do
      subject do
        HearingRequestDocket.new.distribute_appeals(
          distribution, priority: false, limit: 10, genpop: "only_genpop"
        )
      end

      it "only distributes nonpriority, distributable, hearing docket, genpop cases" do
        # won't be included
        create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        matching_all_base_conditions_with_most_recent_held_hearing_tied_to_distribution_judge
        create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge

        # will be included
        appeal = create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        no_held_hearings = non_priority_with_no_held_hearings
        no_hearings = non_priority_with_no_hearings
        outside_affinity = create_nonpriority_distributable_hearing_appeal_tied_to_other_judge_outside_affinity

        expected_result = [appeal, no_held_hearings, no_hearings, outside_affinity]

        tasks = subject

        expect(tasks.length).to eq(expected_result.length)
        expect(tasks.first.class).to eq(DistributedCase)
        expect(tasks.map(&:genpop).uniq).to eq [true]
        expect(tasks.map(&:genpop_query).uniq).to eq ["only_genpop"]
        expect(distribution.distributed_cases.length).to eq(expected_result.length)
        expect(distribution_judge.reload.tasks.map(&:appeal))
          .to match_array(expected_result)
      end
    end

    context "when an appeal already has a distribution" do
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

    context "age_of_n_oldest_priority_appeals_available_to_judge" do
      let(:judge_user) { create(:user) }
      subject { HearingRequestDocket.new.age_of_n_oldest_priority_appeals_available_to_judge(:judge_user, 3) }

      it "returns the receipt_date field of the oldest hearing priority appeals ready for distribution" do
        appeal = create_priority_distributable_hearing_appeal_not_tied_to_any_judge
        expect(HearingRequestDocket.new.count(priority: true, ready: true)).to eq 1
        expect(subject).to eq([appeal.receipt_date])
      end
    end

    context "age_of_n_oldest_nonpriority_appeals_available_to_judge" do
      let(:judge_user) { create(:user) }
      subject { HearingRequestDocket.new.age_of_n_oldest_nonpriority_appeals_available_to_judge(:judge_user, 3) }

      it "returns the receipt_date field of the oldest hearing nonpriority appeals ready for distribution" do
        appeal = create_nonpriority_distributable_hearing_appeal_not_tied_to_any_judge
        expect(HearingRequestDocket.new.count(priority: false, ready: true)).to eq 1
        expect(subject).to eq([appeal.receipt_date])
      end
    end
  end

  private

  def create_appeals_that_should_not_be_returned_by_query
    matching_all_conditions_except_not_tied_to_judge
    matching_all_conditions_except_priority
    matching_all_conditions_except_ready_for_distribution
    matching_all_conditions_except_priority_and_ready_for_distribution
    matching_only_priority_and_ready_for_distribution
    matching_all_base_conditions_with_most_recent_held_hearing_tied_to_judge
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

  def matching_all_conditions_except_not_tied_to_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    hearing = create(:hearing,
                     judge: nil,
                     disposition: "held",
                     appeal: appeal)
    hearing.update(judge: judge_with_team)
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

  def matching_all_base_conditions_with_most_recent_held_hearing_outside_affinity
    num_days = CaseDistributionLever.ama_hearing_case_affinity_days + 1
    days_ago = Time.zone.now.days_ago(num_days)
    most_recent = create(:hearing_day, scheduled_for: days_ago)
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    hearing = create(:hearing,
                     judge: nil,
                     disposition: "held",
                     appeal: appeal,
                     transcript_sent_date: 1.day.ago,
                     hearing_day: most_recent)
    hearing.update(judge: judge_with_team)

    # Artificially set the `assigned_at` of DistributionTask so it's in the past
    DistributionTask.find_by(appeal: appeal).update!(assigned_at: days_ago)

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

  # rubocop:disable Metrics/AbcSize
  def create_nonpriority_unblocked_hearing_appeal_within_affinity
    appeal = create(:appeal,
                    :with_post_intake_tasks,
                    :held_hearing,
                    :denied_advance_on_docket,
                    docket_type: Constants.AMA_DOCKETS.hearing,
                    created_at: 95.days.ago, # accounting for evidence submission window for better realism
                    adding_user: judge_with_team)

    # Complete the ScheduleHearingTask to set up legit tree for when hearing would be created
    ScheduleHearingTask.find_by(appeal: appeal)
      .update!(status: Constants.TASK_STATUSES.completed, closed_at: 90.days.ago)

    # Complete EvidenceSubmissionWindowTask and TranscriptionTask for 90 days after hearing
    EvidenceSubmissionWindowTask.find_by(appeal: appeal)
      .update!(status: Constants.TASK_STATUSES.completed, closed_at: 5.days.ago)

    TranscriptionTask.find_by(appeal: appeal)
      .update!(status: Constants.TASK_STATUSES.completed, closed_at: 5.days.ago)

    # Artificially set the `assigned_at` of DistributionTask so it's in the past
    DistributionTask.find_by(appeal: appeal).update!(
      status: Constants.TASK_STATUSES.assigned,
      assigned_at: 5.days.ago
    )

    # Ensure hearing tied to judge
    Hearing.find_by(appeal: appeal).update!(judge: judge_with_team)

    appeal
  end
  # rubocop:enable Metrics/AbcSize

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

  def create_nonpriority_distributable_hearing_appeal_tied_to_distribution_judge_outside_affinity
    num_days = CaseDistributionLever.ama_hearing_case_affinity_days + 1
    days_ago = Time.zone.now.days_ago(num_days)
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :denied_advance_on_docket,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent = create(:hearing_day, scheduled_for: days_ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: distribution_judge)

    # Artificially set the `assigned_at` of DistributionTask so it's in the past
    DistributionTask.find_by(appeal: appeal).update!(assigned_at: days_ago)

    appeal
  end

  def create_nonpriority_distributable_hearing_appeal_tied_to_other_judge_outside_affinity
    num_days = CaseDistributionLever.ama_hearing_case_affinity_days + 1
    days_ago = Time.zone.now.days_ago(num_days)
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :denied_advance_on_docket,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent = create(:hearing_day, scheduled_for: days_ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: judge_with_team)

    # Artificially set the `assigned_at` of DistributionTask to exceed affinity threshold
    DistributionTask.find_by(appeal: appeal).update!(assigned_at: days_ago)

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

  def matching_all_base_conditions_with_most_recent_held_hearing_tied_to_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)
    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: judge_with_team)

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
    hearing.update(judge: judge_with_team)

    appeal
  end

  def matching_all_base_conditions_with_most_recent_hearing_tied_to_other_judge_but_not_held
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "cancelled", appeal: appeal, hearing_day: most_recent)
    hearing.update(judge: judge_with_team)

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

  def matching_all_base_conditions_with_most_recent_held_hearing_tied_to_other_judge
    appeal = create(:appeal,
                    :ready_for_distribution,
                    :advanced_on_docket_due_to_motion,
                    docket_type: Constants.AMA_DOCKETS.hearing)

    most_recent_hearing_day = create(:hearing_day, scheduled_for: 1.day.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent_hearing_day)
    hearing.update(judge: judge_with_team)

    older_hearing_day = create(:hearing_day, scheduled_for: 2.days.ago)
    hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: older_hearing_day)
    hearing.update(judge: distribution_judge)

    appeal
  end

  def judge_with_team
    active_judge = create(:user, last_login_at: Time.zone.now)
    JudgeTeam.create_for_judge(active_judge)
    active_judge
  end
end
