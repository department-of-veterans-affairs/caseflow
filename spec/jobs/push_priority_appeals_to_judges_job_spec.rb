# frozen_string_literal: true

describe PushPriorityAppealsToJudgesJob, :all_dbs do
  def to_judge_hash(arr)
    arr.each_with_index.map { |count, i| [i, count] }.to_h
  end

  context ".distribute_non_genpop_priority_appeals" do
    before do
      allow_any_instance_of(DirectReviewDocket)
        .to receive(:nonpriority_receipts_per_year)
        .and_return(100)

      allow(Docket)
        .to receive(:nonpriority_decisions_per_year)
        .and_return(1000)
      allow_any_instance_of(PushPriorityAppealsToJudgesJob).to receive(:eligible_judges).and_return(eligible_judges)
    end

    let(:ready_priority_bfkey) { "12345" }
    let(:ready_priority_bfkey2) { "12346" }
    let(:ready_priority_uuid) { "bece6907-3b6f-4c49-a580-6d5f2e1ca65c" }
    let(:ready_priority_uuid2) { "bece6907-3b6f-4c49-a580-6d5f2e1ca65d" }
    let!(:judge_with_ready_priority_cases) do
      create(:user, :judge, :with_vacols_judge_record).tap do |judge|
        vacols_case = create(
          :case,
          :aod,
          bfkey: ready_priority_bfkey,
          bfd19: 1.year.ago,
          bfac: "3",
          bfmpro: "ACT",
          bfcurloc: "81",
          bfdloout: 3.days.ago,
          bfbox: nil,
          folder: build(:folder, tinum: "1801003", titrnum: "123456789S")
        )
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          board_member: judge.vacols_attorney_id
        )

        appeal = create(
          :appeal,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          uuid: ready_priority_uuid,
          docket_type: Constants.AMA_DOCKETS.hearing
        )
        most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
        hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
        hearing.update!(judge: judge)
      end
    end

    let!(:judge_with_ready_nonpriority_cases) do
      create(:user, :judge, :with_vacols_judge_record).tap do |judge|
        vacols_case = create(
          :case,
          bfd19: 1.year.ago,
          bfac: "3",
          bfmpro: "ACT",
          bfcurloc: "81",
          bfdloout: 3.days.ago,
          bfbox: nil,
          folder: build(:folder, tinum: "1801002", titrnum: "123456782S")
        )
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          board_member: judge.vacols_attorney_id
        )

        appeal = create(
          :appeal,
          :ready_for_distribution,
          docket_type: Constants.AMA_DOCKETS.hearing
        )
        most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
        hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
        hearing.update!(judge: judge)
      end
    end

    let!(:judge_with_nonready_priority_cases) do
      create(:user, :judge).tap do |judge|
        create(:staff, :judge_role, user: judge)
        vacols_case = create(
          :case,
          :aod,
          bfd19: 1.year.ago,
          bfac: "3",
          bfmpro: "ACT",
          bfcurloc: "not ready",
          bfdloout: 3.days.ago,
          bfbox: nil,
          folder: build(:folder, tinum: "1801003", titrnum: "123456783S")
        )
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          board_member: judge.vacols_attorney_id
        )

        appeal = create(
          :appeal,
          :advanced_on_docket_due_to_age,
          docket_type: Constants.AMA_DOCKETS.hearing
        )
        most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
        hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
        hearing.update!(judge: judge)
      end
    end
    let!(:ama_only_judge_with_ready_priority_cases) do
      create(:user, :ama_only_judge, :with_vacols_judge_record).tap do |judge|
        vacols_case = create(
          :case,
          :aod,
          bfkey: ready_priority_bfkey2,
          bfd19: 1.year.ago,
          bfac: "3",
          bfmpro: "ACT",
          bfcurloc: "81",
          bfdloout: 3.days.ago,
          bfbox: nil,
          folder: build(:folder, tinum: "1801005", titrnum: "923456790S")
        )
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          board_member: judge.vacols_attorney_id
        )

        appeal = create(
          :appeal,
          :ready_for_distribution,
          :advanced_on_docket_due_to_age,
          uuid: "bece6907-3b6f-4c49-a580-6d5f2e1ca65d",
          docket_type: Constants.AMA_DOCKETS.hearing
        )
        most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
        hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
        hearing.update!(judge: judge)
      end
    end
    let(:eligible_judges) do
      [
        judge_with_ready_priority_cases,
        judge_with_ready_nonpriority_cases,
        judge_with_nonready_priority_cases,
        ama_only_judge_with_ready_priority_cases
      ]
    end

    subject { PushPriorityAppealsToJudgesJob.new.distribute_non_genpop_priority_appeals }

    it "should only distribute the ready priority cases tied to a judge" do
      expect(subject.count).to eq eligible_judges.count
      expect(subject.map { |dist| dist.statistics["batch_size"] }).to match_array [2, 2, 0, 0]

      # Ensure we only distributed the 2 ready legacy and hearing priority cases that are tied to a judge
      distributed_cases = DistributedCase.where(distribution: subject)
      expect(distributed_cases.count).to eq 4
      expect(distributed_cases.map(&:case_id)).to match_array [ready_priority_bfkey, ready_priority_uuid, ready_priority_bfkey2, ready_priority_uuid2]
      # Ensure all docket types cases are distributed, including the 5 cavc evidence submission cases
      expect(distributed_cases.map(&:docket)).to match_array ["legacy", Constants.AMA_DOCKETS.hearing, "legacy", Constants.AMA_DOCKETS.hearing]
      expect(distributed_cases.map(&:priority).uniq).to match_array [true]
      expect(distributed_cases.map(&:genpop).uniq).to match_array [false]
    end
  end

  context ".distribute_genpop_priority_appeals" do
    before do
      allow_any_instance_of(DirectReviewDocket)
        .to receive(:nonpriority_receipts_per_year)
        .and_return(100)

      allow(Docket)
        .to receive(:nonpriority_decisions_per_year)
        .and_return(1000)

      allow_any_instance_of(PushPriorityAppealsToJudgesJob)
        .to receive(:priority_distributions_this_month_for_eligible_judges).and_return(
          judges.each_with_index.map { |judge, i| [judge.id, judge_distributions_this_month[i]] }.to_h
        )
    end

    subject { PushPriorityAppealsToJudgesJob.new.distribute_genpop_priority_appeals }

    let!(:ama_only_judge) { create(:user, :ama_only_judge, :with_vacols_judge_record) }
    let(:judges) { create_list(:user, 4, :judge, :with_vacols_judge_record).prepend(ama_only_judge) }
    let(:judge_distributions_this_month) { (0..4).to_a }
    let!(:legacy_priority_cases) do
      (1..5).map do |i|
        vacols_case = create(
          :case,
          :aod,
          bfd19: 1.year.ago,
          bfac: "1",
          bfmpro: "ACT",
          bfcurloc: "81",
          bfdloout: i.months.ago,
          folder: build(
            :folder,
            tinum: "1801#{format('%<index>03d', index: i)}",
            titrnum: "123456789S"
          )
        )
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date
        )
        vacols_case
      end
    end
    let!(:ready_priority_hearing_cases) do
      (1..5).map do |i|
        appeal = create(:appeal,
                        :advanced_on_docket_due_to_age,
                        :ready_for_distribution,
                        docket_type: Constants.AMA_DOCKETS.hearing)
        appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: i.months.ago)
        appeal.reload
      end
    end
    let!(:ready_priority_evidence_cases) do
      (1..5).map do |i|
        appeal = create(:appeal,
                        :type_cavc_remand,
                        :cavc_ready_for_distribution,
                        docket_type: Constants.AMA_DOCKETS.evidence_submission)
        appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: i.month.ago)
        appeal
      end
    end
    let!(:ready_priority_direct_cases) do
      (1..5).map do |i|
        appeal = create(:appeal,
                        :with_post_intake_tasks,
                        :advanced_on_docket_due_to_age,
                        docket_type: Constants.AMA_DOCKETS.direct_review,
                        receipt_date: 1.month.ago)
        appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: i.month.ago)
        appeal
      end
    end

    let(:priority_count) { Appeal.count { |a| a.aod? || a.cavc? } + VACOLS::Case.count }
    let(:priority_target) { (priority_count + judge_distributions_this_month.sum) / judges.count }



    it "should distribute ready priority appeals to the judges" do
      expect(subject.count).to eq judges.count

      # Ensure we distributed all available ready cases from any docket that are not tied to a judge
      distributed_cases = DistributedCase.where(distribution: subject)
      expect(distributed_cases.count).to eq priority_count
      expect(distributed_cases.map(&:priority).uniq.compact).to match_array [true]
      expect(distributed_cases.map(&:genpop).uniq.compact).to match_array [true]
      expect(distributed_cases.pluck(:docket).uniq).to match_array(Constants::AMA_DOCKETS.keys.unshift("legacy"))
      expect(distributed_cases.group(:docket).count.values.uniq).to match_array [5]
    end

    it "distributes cases to each judge based on their priority target" do
      judges.each_with_index do |judge, i|
        target_distributions = priority_target - judge_distributions_this_month[i]
        distribution = subject.detect { |dist| dist.judge_id == judge.id }
        expect(distribution.statistics["batch_size"]).to eq target_distributions
        distributed_cases = DistributedCase.where(distribution: distribution)
        expect(distributed_cases.count).to eq target_distributions
      end
    end

    it "only distributes ama cases to ama-only judge" do
      distribution = subject.detect { |dist| dist.judge_id == ama_only_judge.id }
      distributed_cases = DistributedCase.where(distribution: distribution)
      intersection = distributed_cases.to_set.intersect? legacy_priority_cases.to_set
      expect(intersection).to eq false
    end
  end

  context ".slack_report" do
    let!(:job) { PushPriorityAppealsToJudgesJob.new }
    let(:previous_distributions) { to_judge_hash([4, 3, 2, 1, 0]) }
    let!(:legacy_priority_case) do
      judge = create(:user, :judge, :with_vacols_judge_record)
      create(
        :case,
        :aod,
        bfd19: 1.year.ago,
        bfac: "1",
        bfmpro: "ACT",
        bfcurloc: "81",
        bfdloout: 1.month.ago,
        folder: build(
          :folder,
          tinum: "1801000",
          titrnum: "123456789S"
        )
      ).tap do |vacols_case|
        create(
          :case_hearing,
          :disposition_held,
          folder_nr: vacols_case.bfkey,
          hearing_date: 5.days.ago.to_date,
          board_member: judge.vacols_attorney_id
        )
      end
    end
    let!(:ready_priority_hearing_case) do
      appeal = FactoryBot.create(:appeal,
                                 :advanced_on_docket_due_to_age,
                                 :ready_for_distribution,
                                 docket_type: Constants.AMA_DOCKETS.hearing)
      appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: 2.months.ago)
      most_recent = create(:hearing_day, scheduled_for: 1.day.ago)
      hearing = create(:hearing, judge: nil, disposition: "held", appeal: appeal, hearing_day: most_recent)
      hearing.update!(judge: create(:user, :judge, :with_vacols_judge_record))
      appeal.reload
    end
    let!(:ready_priority_evidence_case) do
      appeal = create(:appeal,
                      :with_post_intake_tasks,
                      :advanced_on_docket_due_to_age,
                      docket_type: Constants.AMA_DOCKETS.evidence_submission)
      appeal.tasks.find_by(type: EvidenceSubmissionWindowTask.name).completed!
      appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: 3.months.ago)
      appeal
    end
    let!(:ready_priority_direct_case) do
      appeal = create(:appeal,
                      :with_post_intake_tasks,
                      :advanced_on_docket_due_to_age,
                      docket_type: Constants.AMA_DOCKETS.direct_review,
                      receipt_date: 1.month.ago)
      appeal.tasks.find_by(type: DistributionTask.name).update(assigned_at: 4.months.ago)
      appeal
    end

    let(:distributed_cases) do
      (0...5).map do |count|
        distribution = build(:distribution, statistics: { "batch_size" => count })
        distribution.save(validate: false)
        distribution
      end
    end

    subject { job.slack_report }

    before do
      job.instance_variable_set(:@tied_distributions, distributed_cases)
      job.instance_variable_set(:@genpop_distributions, distributed_cases)
      allow_any_instance_of(PushPriorityAppealsToJudgesJob)
        .to receive(:priority_distributions_this_month_for_eligible_judges).and_return(previous_distributions)
      allow_any_instance_of(DocketCoordinator).to receive(:genpop_priority_count).and_return(20)
    end

    it "returns ids and age of ready priority appeals not distributed" do
      expect(subject.second).to eq "*Number of cases tied to judges distributed*: 10"
      expect(subject.third).to eq "*Number of general population cases distributed*: 10"

      today = Time.zone.now.to_date
      legacy_days_waiting = (today - legacy_priority_case.bfdloout.to_date).to_i
      expect(subject[3]).to eq "*Age of oldest legacy case*: #{legacy_days_waiting} days"
      direct_review_days_waiting = (today - ready_priority_direct_case.ready_for_distribution_at.to_date).to_i
      expect(subject[4]).to eq "*Age of oldest direct_review case*: #{direct_review_days_waiting} days"
      evidence_submission_days_waiting = (today - ready_priority_evidence_case.ready_for_distribution_at.to_date).to_i
      expect(subject[5]).to eq "*Age of oldest evidence_submission case*: #{evidence_submission_days_waiting} days"
      hearing_days_waiting = (today - ready_priority_hearing_case.ready_for_distribution_at.to_date).to_i
      expect(subject[6]).to eq "*Age of oldest hearing case*: #{hearing_days_waiting} days"

      expect(subject[7]).to eq "*Number of appeals _not_ distributed*: 4"

      expect(subject[10]).to eq "Priority Target: 6"
      expect(subject[11]).to eq "Previous monthly distributions: #{previous_distributions}"
      expect(subject[12].include?(legacy_priority_case.bfkey)).to be true
      expect(subject[13].include?(ready_priority_hearing_case.uuid)).to be true
      expect(subject[13].include?(ready_priority_evidence_case.uuid)).to be true
      expect(subject[13].include?(ready_priority_direct_case.uuid)).to be true

      expect(subject.last).to eq COPY::PRIORITY_PUSH_WARNING_MESSAGE
    end
  end

  context ".eligible_judge_target_distributions_with_leftovers" do
    shared_examples "correct target distributions with leftovers" do
      before do
        allow_any_instance_of(PushPriorityAppealsToJudgesJob)
          .to receive(:priority_distributions_this_month_for_eligible_judges)
          .and_return(to_judge_hash(distribution_counts))
        allow_any_instance_of(DocketCoordinator).to receive(:genpop_priority_count).and_return(priority_count)
      end

      subject { PushPriorityAppealsToJudgesJob.new.eligible_judge_target_distributions_with_leftovers }

      it "returns hash of how many cases should be distributed to each judge that is below the priority target " \
        "including any leftover cases" do
        expect(subject.values).to match_array expected_priority_targets_with_leftovers
      end
    end

    context "when the distributions this month have been even" do
      shared_examples "even distributions this month" do
        context "when there are more eligible judges than cases to distribute" do
          let(:eligible_judge_count) { 10 }
          let(:priority_count) { 5 }
          # Priority target will be 0, 5 cases are allotted to 5 judges
          let(:expected_priority_targets_with_leftovers) { Array.new(priority_count, 1) }

          it_behaves_like "correct target distributions with leftovers"
        end

        context "when there are more cases to distribute than eligible judges" do
          let(:eligible_judge_count) { 5 }
          let(:priority_count) { 10 }
          # Priority target will be 2, evenly distributed amongst judges
          let(:expected_priority_targets_with_leftovers) { Array.new(eligible_judge_count, 2) }

          it_behaves_like "correct target distributions with leftovers"

          context "when the cases cannot be evenly distributed" do
            let(:priority_count) { 9 }
            # Priority target rounds down, leftover 4 cases are allotted to judges with the fewest cases to distribute
            let(:expected_priority_targets_with_leftovers) { [1, 2, 2, 2, 2] }

            it_behaves_like "correct target distributions with leftovers"
          end
        end
      end

      let(:distribution_counts) { Array.new(eligible_judge_count, number_of_distributions) }

      context "when there have been no distributions this month" do
        let(:number_of_distributions) { 0 }

        it_behaves_like "even distributions this month"
      end

      context "when there have been some distributions this month" do
        let(:number_of_distributions) { eligible_judge_count * 2 }

        it_behaves_like "even distributions this month"
      end
    end

    context "when previous distributions counts are not greater than the priority target" do
      let(:distribution_counts) { [10, 15, 20, 25, 30] }
      let(:priority_count) { 75 }
      # 75 should be able to be divided up to get all judges up to 35
      let(:expected_priority_targets_with_leftovers) { [25, 20, 15, 10, 5] }

      it_behaves_like "correct target distributions with leftovers"

      context "when cases are not evenly distributable" do
        let(:priority_count) { 79 }
        # Priority target still is 35, the leftover 4 cases are allotted to judges with the fewest cases to distribute
        let(:expected_priority_targets_with_leftovers) { [25, 21, 16, 11, 6] }

        it_behaves_like "correct target distributions with leftovers"
      end
    end

    context "when previous distributions counts are greater than the priority target" do
      let(:distribution_counts) { [0, 0, 22, 28, 50] }
      let(:priority_count) { 50 }
      # The two judges with 0 cases should receive 24 cases, the one judge with 22 cases should recieve 2, leaving us
      # with [24, 24, 24, 28, 50] to hopefully even out more in the next distribution.
      let(:expected_priority_targets_with_leftovers) { [24, 24, 2] }

      it_behaves_like "correct target distributions with leftovers"

      context "when the distribution counts are even more disparate" do
        let(:distribution_counts) { [0, 0, 5, 9, 26, 27, 55, 56, 89, 100] }
        let(:priority_count) { 50 }
        # Ending counts should be [16, 16, 16, 16, 26, 27, 55, 56, 89, 100], perfectly using up all 50 cases
        let(:expected_priority_targets_with_leftovers) { [16, 16, 11, 7] }

        it_behaves_like "correct target distributions with leftovers"

        context "when there are leftover cases" do
          let(:priority_count) { 53 }
          # Ending counts should be [16, 17, 17, 17, 26, 27, 55, 56, 89, 100]
          let(:expected_priority_targets_with_leftovers) { [16, 17, 12, 8] }

          it_behaves_like "correct target distributions with leftovers"
        end
      end
    end

    context "tracking distributions over time" do
      let(:number_judges) { rand(5..10) }
      let(:priority_count) { rand(10..30) }
      # Github Issue 15984, this stops this test from flaking, by making sure the
      # expects below are achievable for all values rand() will produce.
      let(:max_preexisting_cases) { (priority_count / (number_judges - 1)).floor }

      before do
        # Mock cases already distributed this month
        @distribution_counts = to_judge_hash(Array.new(number_judges).map { rand(max_preexisting_cases) })
        allow_any_instance_of(PushPriorityAppealsToJudgesJob)
          .to receive(:priority_distributions_this_month_for_eligible_judges).and_return(@distribution_counts)
        allow_any_instance_of(PushPriorityAppealsToJudgesJob)
          .to receive(:ready_genpop_priority_appeals_count).and_return(priority_count)
      end

      it "evens out over multiple calls" do
        4.times do
          # Mock distributing cases each week
          target_distributions = PushPriorityAppealsToJudgesJob.new.eligible_judge_target_distributions_with_leftovers
          @distribution_counts.merge!(target_distributions) { |_, prev_dists, target_dist| prev_dists + target_dist }
        end
        final_counts = @distribution_counts.values.uniq
        # Expect no more than two distinct counts, no more than 1 apart
        expect(final_counts.max - final_counts.min).to be <= 1
        expect(final_counts.count).to be <= 2
      end
    end
  end

  context ".leftover_cases_count" do
    before do
      allow_any_instance_of(PushPriorityAppealsToJudgesJob)
        .to receive(:target_distributions_for_eligible_judges).and_return(target_distributions)
      allow_any_instance_of(DocketCoordinator).to receive(:genpop_priority_count).and_return(priority_count)
    end

    subject { PushPriorityAppealsToJudgesJob.new.leftover_cases_count }

    context "when the number of cases to distribute is evenly divisible by the number of judges that need cases" do
      let(:eligible_judge_count) { 4 }
      let(:priority_count) { 100 }
      let(:target_distributions) do
        Array.new(eligible_judge_count, priority_count / eligible_judge_count)
          .each_with_index
          .map { |count, i| [i, count] }.to_h
      end

      it "returns no leftover cases" do
        expect(subject).to eq 0
      end
    end

    context "when the number of cases can be distributed to all judges evenly" do
      let(:priority_count) { target_distributions.values.sum }
      let(:target_distributions) { to_judge_hash([5, 10, 15, 20, 25]) }

      it "returns no leftover cases" do
        expect(subject).to eq 0
      end
    end

    context "when the number of cases are not evenly distributable bewteen all judges" do
      let(:leftover_cases_count) { target_distributions.count - 1 }
      let(:priority_count) { target_distributions.values.sum + leftover_cases_count }
      let(:target_distributions) { to_judge_hash([5, 10, 15, 20, 25]) }

      it "returns the correct number of leftover cases" do
        expect(subject).to eq leftover_cases_count
      end
    end
  end

  context ".target_distributions_for_eligible_judges" do
    shared_examples "correct target distributions" do
      before do
        allow_any_instance_of(PushPriorityAppealsToJudgesJob)
          .to receive(:priority_distributions_this_month_for_eligible_judges)
          .and_return(to_judge_hash(distribution_counts))
        allow_any_instance_of(DocketCoordinator).to receive(:genpop_priority_count).and_return(priority_count)
      end

      subject { PushPriorityAppealsToJudgesJob.new.target_distributions_for_eligible_judges }

      it "returns hash of how many cases should be distributed to each judge that is below the priority target " \
        "excluding any leftover cases" do
        expect(subject).to eq to_judge_hash(expected_priority_targets)
      end
    end

    context "when the distributions this month have been even" do
      let(:distribution_counts) { Array.new(eligible_judge_count, number_of_distributions) }

      context "when there have been no distributions this month" do
        let(:number_of_distributions) { 0 }

        context "when there are more eligible judges than cases to distribute" do
          let(:eligible_judge_count) { 10 }
          let(:priority_count) { 5 }
          # Priority target will be 0, cases will be allotted later from the leftover cases
          let(:expected_priority_targets) { Array.new(eligible_judge_count, 0) }

          it_behaves_like "correct target distributions"
        end

        context "when there are more cases to distribute than eligible judges" do
          let(:eligible_judge_count) { 5 }
          let(:priority_count) { 10 }
          # Priority target will be 2, evenly distributed amongst judges
          let(:expected_priority_targets) { Array.new(eligible_judge_count, 2) }

          it_behaves_like "correct target distributions"

          context "when the cases cannot be evenly distributed" do
            let(:priority_count) { 9 }
            # Priority target rounds down, the leftover 4 cases will be allotted later in the algorithm
            let(:expected_priority_targets) { Array.new(eligible_judge_count, 1) }

            it_behaves_like "correct target distributions"
          end
        end
      end

      context "when there have been some distributions this month" do
        let(:number_of_distributions) { eligible_judge_count * 2 }

        context "when there are more eligible judges than cases to distribute" do
          let(:eligible_judge_count) { 10 }
          let(:priority_count) { 5 }
          # Priority target is equal to how many cases have already been distributed. Cases will be allotted from the
          # leftover cases. 5 judges will each be distributed 1 case
          let(:expected_priority_targets) { Array.new(eligible_judge_count, 0) }

          it_behaves_like "correct target distributions"
        end

        context "when there are more cases to distribute than eligible judges" do
          let(:eligible_judge_count) { 5 }
          let(:priority_count) { 10 }
          # Priority target will be evenly distributed amongst judges
          let(:expected_priority_targets) { Array.new(eligible_judge_count, 2) }

          it_behaves_like "correct target distributions"

          context "when the cases cannot be evenly distributed" do
            let(:priority_count) { 9 }
            # Priority target rounds down, the leftover 4 cases will be allotted later in the algorithm
            let(:expected_priority_targets) { Array.new(eligible_judge_count, 1) }

            it_behaves_like "correct target distributions"
          end
        end
      end
    end

    context "when previous distributions counts are not greater than the priority target" do
      let(:distribution_counts) { [10, 15, 20, 25, 30] }
      let(:priority_count) { 75 }
      # 75 should be able to be divided up to get all judges up to 35
      let(:expected_priority_targets) { [25, 20, 15, 10, 5] }

      it_behaves_like "correct target distributions"

      context "when cases are not evenly distributable" do
        let(:priority_count) { 79 }
        # Priority target still is 35, the leftover 4 cases will be allotted later in the algorithm

        it_behaves_like "correct target distributions"
      end
    end

    context "when previous distributions counts are greater than the priority target" do
      let(:distribution_counts) { [0, 0, 22, 28, 50] }
      let(:priority_count) { 50 }
      # The two judges with 0 cases should receive 24 cases, the one judge with 22 cases should recieve 2, leaving us
      # with [24, 24, 24, 28, 50] to hopefully even out more in the next distribution.
      let(:expected_priority_targets) { [24, 24, 2] }

      it_behaves_like "correct target distributions"

      context "when the dirstibution counts are even more disparate" do
        let(:distribution_counts) { [0, 0, 5, 9, 26, 27, 55, 56, 89, 100] }
        let(:priority_count) { 50 }
        # Ending counts should be [16, 16, 16, 16, 26, 27, 55, 56, 89, 100], perfectly using up all 50 cases
        let(:expected_priority_targets) { [16, 16, 11, 7] }

        it_behaves_like "correct target distributions"
      end
    end
  end

  context ".priority_target" do
    shared_examples "correct target" do
      before do
        allow_any_instance_of(PushPriorityAppealsToJudgesJob)
          .to receive(:priority_distributions_this_month_for_eligible_judges)
          .and_return(to_judge_hash(distribution_counts))
        allow_any_instance_of(DocketCoordinator).to receive(:genpop_priority_count).and_return(priority_count)
      end

      subject { PushPriorityAppealsToJudgesJob.new.priority_target }

      it "calculates a target that distributes cases evenly over one month" do
        expect(subject).to eq expected_priority_target
      end
    end

    context "when the distributions this month have been even" do
      let(:distribution_counts) { Array.new(eligible_judge_count, number_of_distributions) }

      context "when there have been no distributions this month" do
        let(:number_of_distributions) { 0 }

        context "when there are more eligible judges than cases to distribute" do
          let(:eligible_judge_count) { 10 }
          let(:priority_count) { 5 }
          # Priority target will be 0, cases will be allotted from the leftover cases. judges will be distributed 1 case
          let(:expected_priority_target) { 0 }

          it_behaves_like "correct target"
        end

        context "when there are more cases to distribute than eligible judges" do
          let(:eligible_judge_count) { 5 }
          let(:priority_count) { 10 }
          # Priority target will be evenly distributed amongst judges
          let(:expected_priority_target) { 2 }

          it_behaves_like "correct target"

          context "when the cases cannot be evenly distributed" do
            let(:priority_count) { 9 }
            # Priority target rounds down, the leftover 4 cases will be allotted later in the algorithm
            let(:expected_priority_target) { 1 }

            it_behaves_like "correct target"
          end
        end
      end

      context "when there have been some distributions this month" do
        let(:number_of_distributions) { 10 }

        context "when there are more eligible judges than cases to distribute" do
          let(:eligible_judge_count) { 10 }
          let(:priority_count) { 5 }
          # Priority target is equal to how many cases have already been distributed. Cases will be allotted from the
          # leftover cases. judges will each be distributed 1 case
          let(:expected_priority_target) { 10 }

          it_behaves_like "correct target"
        end

        context "when there are more cases to distribute than eligible judges" do
          let(:eligible_judge_count) { 5 }
          let(:priority_count) { 10 }
          # Priority target will be evenly distributed amongst judges
          let(:expected_priority_target) { 12 }

          it_behaves_like "correct target"

          context "when the cases cannot be evenly distributed" do
            let(:priority_count) { 9 }
            # Priority target rounds down, the leftover 4 cases will be allotted later in the algorithm
            let(:expected_priority_target) { 11 }

            it_behaves_like "correct target"
          end
        end
      end
    end

    context "when previous distributions counts are not greater than the priority target" do
      let(:distribution_counts) { [10, 15, 20, 25, 30] }
      let(:priority_count) { 75 }
      # 75 should be able to be divided up to get all judges up to 35
      let(:expected_priority_target) { 35 }

      it_behaves_like "correct target"

      context "when cases are not evenly distributable" do
        let(:priority_count) { 79 }
        # Priority target still is 35, the leftover 4 cases will be allotted later in the algorithm

        it_behaves_like "correct target"
      end
    end

    context "when previous distributions counts are greater than the priority target" do
      let(:distribution_counts) { [0, 0, 22, 28, 50] }
      let(:priority_count) { 50 }
      # The two judges with 0 cases should receive 24 cases, the one judge with 22 cases should recieve 2, leaving us
      # with [24, 24, 24, 28, 50] to hopefully even out more in the next distribution.
      let(:expected_priority_target) { 24 }

      it_behaves_like "correct target"

      context "when the dirstibution counts are even more disparate" do
        let(:distribution_counts) { [0, 0, 5, 9, 26, 27, 55, 56, 89, 100] }
        let(:priority_count) { 50 }
        # Ending counts should be [16, 16, 16, 16, 26, 27, 55, 56, 89, 100], perfectly using up all 50 cases
        let(:expected_priority_target) { 16 }

        it_behaves_like "correct target"
      end
    end
  end

  context ".priority_distributions_this_month_for_eligible_judges" do
    let!(:judge_without_team) { create(:user) }
    let!(:judge_without_active_team) { create(:user).tap { |judge| JudgeTeam.create_for_judge(judge).inactive! } }
    let!(:judge_without_priority_push_team) do
      create(:user).tap { |judge| JudgeTeam.create_for_judge(judge).update(accepts_priority_pushed_cases: false) }
    end
    let!(:judge_with_org) { create(:user).tap { |judge| create(:organization).add_user(judge) } }
    let!(:judge_with_team_and_distributions) { create(:user, :judge) }
    let!(:judge_with_team_without_distributions) { create(:user, :judge) }

    let!(:distributions_for_valid_judge) { 6 }

    subject { PushPriorityAppealsToJudgesJob.new.priority_distributions_this_month_for_eligible_judges }

    before do
      allow_any_instance_of(PushPriorityAppealsToJudgesJob)
        .to receive(:priority_distributions_this_month_for_all_judges)
        .and_return(
          judge_without_team.id => 5,
          judge_without_active_team.id => 5,
          judge_without_priority_push_team.id => 5,
          judge_with_org.id => 5,
          judge_with_team_and_distributions.id => distributions_for_valid_judge
        )
    end

    it "only returns hash containing the distribution counts of judges that can be pushed priority appeals" do
      [
        judge_without_team,
        judge_without_active_team,
        judge_without_priority_push_team,
        judge_with_org
      ].each do |ineligible_judge|
        expect(subject[ineligible_judge]).to be nil
      end
      expect(subject[judge_with_team_and_distributions.id]).to eq distributions_for_valid_judge
      expect(subject[judge_with_team_without_distributions.id]).to eq 0
    end
  end

  context ".eligible_judges" do
    let!(:judge_without_team) { create(:user) }
    let!(:judge_without_active_team) { create(:user).tap { |judge| JudgeTeam.create_for_judge(judge).inactive! } }
    let!(:judge_without_priority_push_team) do
      create(:user, :judge).tap { |judge| JudgeTeam.for_judge(judge).update(accepts_priority_pushed_cases: false) }
    end
    let!(:judge_with_org) { create(:user).tap { |judge| create(:organization).add_user(judge) } }
    let!(:judge_with_team) { create(:user, :judge) }

    subject { PushPriorityAppealsToJudgesJob.new.eligible_judges }

    it "only returns judges of active judge teams" do
      expect(subject).to match_array([judge_with_team])
    end
  end

  context ".priority_distributions_this_month_for_all_judges" do
    let(:batch_size) { 20 }
    let!(:judge_with_no_priority_distributions) do
      create(:user, :judge, :with_vacols_judge_record) do |judge|
        create(
          :distribution,
          judge: judge,
          priority_push: false,
          completed_at: 1.day.ago,
          statistics: { "batch_size": batch_size }
        ).tap { |distribution| distribution.update!(status: :completed) }
      end
    end
    let!(:judge_with_no_recent_distributions) do
      create(:user, :judge, :with_vacols_judge_record) do |judge|
        create(
          :distribution,
          judge: judge,
          priority_push: true,
          completed_at: 41.days.ago,
          statistics: { "batch_size": batch_size }
        ).tap { |distribution| distribution.update!(status: :completed) }
      end
    end
    let!(:judge_with_no_completed_distributions) do
      create(:user, :judge, :with_vacols_judge_record) do |judge|
        create(
          :distribution,
          judge: judge,
          priority_push: true,
          statistics: { "batch_size": batch_size }
        )
      end
    end
    let!(:judge_with_a_valid_distribution) do
      create(:user, :judge, :with_vacols_judge_record) do |judge|
        create(
          :distribution,
          judge: judge,
          priority_push: true,
          completed_at: 1.day.ago,
          statistics: { "batch_size": batch_size }
        ).tap { |distribution| distribution.update!(status: :completed) }
      end
    end
    let!(:judge_with_multiple_valid_distributions) do
      create(:user, :judge, :with_vacols_judge_record) do |judge|
        create(
          :distribution,
          judge: judge,
          priority_push: true,
          completed_at: 1.day.ago,
          statistics: { "batch_size": batch_size }
        ).tap { |distribution| distribution.update!(status: :completed) }
        create(
          :distribution,
          judge: judge,
          priority_push: true,
          completed_at: 1.day.ago,
          statistics: { "batch_size": batch_size }
        ).tap { |distribution| distribution.update!(status: :completed) }
      end
    end

    subject { PushPriorityAppealsToJudgesJob.new.priority_distributions_this_month_for_all_judges }

    it "returns the sum of the batch sizes from all valid distributions for each judge" do
      expect(subject.keys).to match_array(
        [judge_with_a_valid_distribution.id, judge_with_multiple_valid_distributions.id]
      )
      expect(subject[judge_with_a_valid_distribution.id]).to eq batch_size
      expect(subject[judge_with_multiple_valid_distributions.id]).to eq batch_size * 2
    end
  end

  context ".priority_distributions_this_month" do
    let!(:non_priority_distribution) do
      create(
        :distribution,
        judge: create(:user, :with_vacols_judge_record),
        priority_push: false,
        completed_at: 1.day.ago
      ).tap { |distribution| distribution.update!(status: :completed) }
    end
    let!(:pending_priority_distribution) do
      create(
        :distribution,
        judge: create(:user, :with_vacols_judge_record),
        priority_push: true
      )
    end
    let!(:older_priority_distribution) do
      create(
        :distribution,
        judge: create(:user, :with_vacols_judge_record),
        priority_push: true,
        completed_at: 41.days.ago
      ).tap { |distribution| distribution.update!(status: :completed) }
    end
    let!(:recent_completed_priority_distribution) do
      create(
        :distribution,
        judge: create(:user, :with_vacols_judge_record),
        priority_push: true,
        completed_at: 1.day.ago
      ).tap { |distribution| distribution.update!(status: :completed) }
    end

    subject { PushPriorityAppealsToJudgesJob.new.priority_distributions_this_month }

    it "only returns recently completed priority distributions" do
      expect(subject.count).to eq 1
      expect(subject.first).to eq recent_completed_priority_distribution
    end
  end

  context "when the entire job fails" do
    let(:error_msg) { "Some dummy error" }

    it "sends a message to Slack that includes the error" do
      slack_msg = ""
      allow_any_instance_of(SlackService).to receive(:send_notification) { |_, first_arg| slack_msg = first_arg }

      allow_any_instance_of(described_class).to receive(:distribute_non_genpop_priority_appeals).and_raise(error_msg)
      described_class.perform_now

      expected_msg = ".ERROR. after running for .*: #{error_msg}"
      expect(slack_msg).to match(/^#{expected_msg}/)
    end
  end
end
