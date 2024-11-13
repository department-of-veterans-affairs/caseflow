# frozen_string_literal: true

describe ByDocketDateDistribution, :all_dbs do
  class ByDocketDateDistributionTest
    include ActiveModel::Model
    include ByDocketDateDistribution

    attr_accessor :judge

    # the value here doesn't matter but if a test is checking batch_size then its values need to add to this
    def batch_size
      12
    end

    def team_size
      5
    end

    def judge_tasks
      []
    end

    def judge_legacy_tasks
      []
    end
  end

  before(:each) do
    FeatureToggle.enable!(:priority_acd)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
    @new_acd = ByDocketDateDistributionTest.new(judge: User.new)
    create(:case_distribution_lever, :batch_size_per_attorney)
    create(:case_distribution_lever, :ama_hearing_case_affinity_days)
    create(:case_distribution_lever, :ama_hearing_case_aod_affinity_days)
    create(:case_distribution_lever, :ama_direct_review_docket_time_goals)
    create(:case_distribution_lever, :ama_evidence_submission_docket_time_goals)
    create(:case_distribution_lever, :ama_hearing_docket_time_goals)
    create(:case_distribution_lever, :disable_legacy_non_priority)
    create(:case_distribution_lever, :disable_legacy_priority)
    create(:case_distribution_lever, :cavc_affinity_days)
    create(:case_distribution_lever, :cavc_aod_affinity_days)
    create(:case_distribution_lever, :aoj_cavc_affinity_days)
    create(:case_distribution_lever, :aoj_aod_affinity_days)
    create(:case_distribution_lever, :aoj_affinity_days)
  end

  # used to put {num} ambiguous objects into an array to mock the return array from requested_distribution
  def add_object_to_return_array(num)
    array = []
    num.times do
      array << Object.new
    end
    array
  end

  def add_dates_to_date_array(num)
    array = []
    # Date parses to 01 Sep 2022
    date = Date.parse("1/9/2022")
    num.times do
      array << date
      date -= 1
    end
    array
  end

  # hash is set up to only use direct_review/evidence_submission so that legacy/hearing can be mocked
  # the total for each of these dockets needs to equal the batch_size above
  let(:priority_count_hash) { { legacy: 3, direct_review: 3, evidence_submission: 3, hearing: 3 } }

  context "#priority_push_distribution" do
    it "calls each method and returns the array of objects received from each method" do
      # distribute all priority appeals from all dockets
      expect(@new_acd).to receive(:num_oldest_priority_appeals_for_judge_by_docket)
        .with(@new_acd, @new_acd.batch_size, genpop: nil)
        .and_return(priority_count_hash)

      expect_any_instance_of(LegacyDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:legacy], genpop: nil)
        .and_return(add_object_to_return_array(priority_count_hash[:legacy]))

      expect_any_instance_of(DirectReviewDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:direct_review], genpop: nil)
        .and_return(add_object_to_return_array(priority_count_hash[:direct_review]))

      expect_any_instance_of(EvidenceSubmissionDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:evidence_submission], genpop: nil)
        .and_return(add_object_to_return_array(priority_count_hash[:evidence_submission]))

      expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:hearing], genpop: nil)
        .and_return(add_object_to_return_array(priority_count_hash[:hearing]))

      # priority_push_distribution is private so .send is used to directly call it
      @new_acd.send :priority_push_distribution, 12
    end
  end

  let(:nonpriority_count_hash) { { legacy: 3, direct_review: 3, evidence_submission: 3, hearing: 3 } }

  context "#requested_distribution" do
    it "calls each method and returns the array of objects received from each method" do
      # returning {} from num_oldest_priority_appeals_by_docket will bypass
      # distribute_limited_priority_appeals_from_all_dockets not iterate over anything
      expect(@new_acd).to receive(:num_oldest_priority_appeals_for_judge_by_docket)
        .and_return({})

      # distribute all nonpriority appeals from all dockets
      expect(@new_acd).to receive(:num_oldest_nonpriority_appeals_for_judge_by_docket)
        .with(@new_acd, @new_acd.batch_size)
        .and_return(nonpriority_count_hash)

      expect_any_instance_of(LegacyDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: false, style: "request", limit: nonpriority_count_hash[:legacy])
        .and_return(add_object_to_return_array(nonpriority_count_hash[:legacy]))

      expect_any_instance_of(DirectReviewDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: false, style: "request", limit: nonpriority_count_hash[:direct_review])
        .and_return(add_object_to_return_array(nonpriority_count_hash[:direct_review]))

      expect_any_instance_of(EvidenceSubmissionDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: false, style: "request", limit: nonpriority_count_hash[:evidence_submission])
        .and_return(add_object_to_return_array(nonpriority_count_hash[:evidence_submission]))

      expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: false, style: "request", limit: nonpriority_count_hash[:hearing])
        .and_return(add_object_to_return_array(nonpriority_count_hash[:hearing]))

      # requested_distribution is private so .send is used to directly call it
      return_array = @new_acd.send :requested_distribution, nil
      expect(return_array.count).to eq(@new_acd.batch_size)
    end

    it "will limit to 10 nonpriority iterations if not enough cases exist to reach the batch size" do
      by_docket_date_distribution_module = @new_acd
      return_array = by_docket_date_distribution_module.send :requested_distribution, nil

      # @nonpriority_iterations is limited to 10 in the by_docket_date_distribution file
      expect(by_docket_date_distribution_module.instance_variable_get(:@nonpriority_iterations))
        .to eq 2
      expect(return_array.empty?).to be true
    end
  end

  context "#num_oldest_priority_appeals_for_judge_by_docket" do
    it "returns an empty hash if provided num is zero" do
      return_value = @new_acd.send :num_oldest_priority_appeals_for_judge_by_docket, @new_acd, 0
      expect(return_value).to eq({})
    end

    it "calls each docket and sorts the return values if num > 0" do
      expect_any_instance_of(LegacyDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size, genpop: nil)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(DirectReviewDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size, genpop: nil)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(EvidenceSubmissionDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size, genpop: nil)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(HearingRequestDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd, @new_acd.batch_size, genpop: nil)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      return_array = @new_acd.send(
        :num_oldest_priority_appeals_for_judge_by_docket,
        @new_acd,
        @new_acd.batch_size,
        genpop: nil
      )
      expect(return_array).to eq(priority_count_hash)
    end
  end

  context "#num_oldest_nonpriority_appeals_for_judge_by_docket" do
    it "returns an empty hash if provided num is zero" do
      return_value = @new_acd.send :num_oldest_nonpriority_appeals_for_judge_by_docket, @new_acd, 0
      expect(return_value).to eq({})
    end

    it "calls each docket and sorts the return values if num > 0" do
      expect_any_instance_of(LegacyDocket).to receive(:age_of_n_oldest_nonpriority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(DirectReviewDocket).to receive(:age_of_n_oldest_nonpriority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(EvidenceSubmissionDocket)
        .to receive(:age_of_n_oldest_nonpriority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(HearingRequestDocket).to receive(:age_of_n_oldest_nonpriority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      return_array = @new_acd.send(
        :num_oldest_nonpriority_appeals_for_judge_by_docket,
        @new_acd,
        @new_acd.batch_size
      )
      expect(return_array).to eq(nonpriority_count_hash)
    end
  end

  context "#ama_statistics" do
    before do
      FeatureToggle.enable!(:acd_distribute_by_docket_date)
      create(:case_distribution_lever, :cavc_affinity_days)
      @new_acd.instance_variable_set(:@appeals, [])
    end

    after { FeatureToggle.disable!(:acd_distribute_by_docket_date) }

    it "returns a hash with keys" do
      ama_statistics = @new_acd.send(:ama_statistics)
      statistics = ama_statistics[:statistics]

      expect(statistics).to have_key(:batch_size)
      expect(statistics).to have_key(:total_batch_size)
      expect(statistics).to have_key(:priority_target)
      expect(statistics).to have_key(:priority_count)
      expect(statistics).to have_key(:nonpriority_count)
      expect(statistics).to have_key(:nonpriority_iterations)
      expect(statistics).to have_key(:sct_appeals)

      ineligible_judge_stats = ama_statistics[:ineligible_judge_stats]
      expect(ineligible_judge_stats).to have_key(:distributed_cases_tied_to_ineligible_judges)

      judge_stats = ama_statistics[:judge_stats]

      expect(judge_stats).to have_key(:team_size)
      expect(judge_stats).to have_key(:ama_judge_assigned_tasks)
      expect(judge_stats).to have_key(:legacy_assigned_tasks)
      expect(judge_stats).to have_key(:settings)

      @new_acd.dockets.each_key do |sym|
        # priority stats
        expect(ama_statistics).to have_key("#{sym}_priority_stats".to_sym)

        priority_stats = ama_statistics["#{sym}_priority_stats".to_sym]
        expect(priority_stats).to have_key(:count)
        expect(priority_stats).to have_key(:affinity_date)

        priority_affinity_date = priority_stats[:affinity_date]
        expect(priority_affinity_date).to have_key(:in_window)
        expect(priority_affinity_date).to have_key(:out_of_window)

        # non priority stats
        expect(ama_statistics).to have_key("#{sym}_stats".to_sym)
        nonpriority_stats = ama_statistics["#{sym}_stats".to_sym]
        expect(nonpriority_stats).to have_key(:count)
        expect(nonpriority_stats).to have_key(:affinity_date)

        nonpriority_affinity_date = nonpriority_stats[:affinity_date]
        expect(nonpriority_affinity_date).to have_key(:in_window)
        expect(nonpriority_affinity_date).to have_key(:out_of_window)
      end
    end

    context "when individual docket statistics are toggled off" do
      before do
        FeatureToggle.enable!("disable_legacy_distribution_stats")
        FeatureToggle.enable!("disable_direct_review_distribution_stats")
        FeatureToggle.enable!("disable_evidence_submission_distribution_stats")
        FeatureToggle.enable!("disable_hearing_distribution_stats")
        FeatureToggle.enable!("disable_aoj_legacy_distribution_stats")
      end

      after do
        FeatureToggle.disable!("disable_legacy_distribution_stats")
        FeatureToggle.disable!("disable_direct_review_distribution_stats")
        FeatureToggle.disable!("disable_evidence_submission_distribution_stats")
        FeatureToggle.disable!("disable_hearing_distribution_stats")
        FeatureToggle.disable!("disable_aoj_legacy_distribution_stats")
      end

      it "does not attempt to generate individual docket statistics" do
        expect_any_instance_of(LegacyDocket).not_to receive(:affinity_date_count)
        expect_any_instance_of(DirectReviewDocket).not_to receive(:affinity_date_count)
        expect_any_instance_of(EvidenceSubmissionDocket).not_to receive(:affinity_date_count)
        expect_any_instance_of(HearingRequestDocket).not_to receive(:affinity_date_count)
        expect_any_instance_of(AojLegacyDocket).not_to receive(:affinity_date_count)

        ama_statistics = @new_acd.send(:ama_statistics)

        @new_acd.dockets.each_key do |sym|
          expect(ama_statistics).to have_key("#{sym}_priority_stats".to_sym)
          priority_stats = ama_statistics["#{sym}_priority_stats".to_sym]
          expect(priority_stats).to be_empty

          expect(ama_statistics).to have_key("#{sym}_stats".to_sym)
          nonpriority_stats = ama_statistics["#{sym}_stats".to_sym]
          expect(nonpriority_stats).to be_empty
        end
      end
    end

    context "handles errors without stopping a distribution" do
      let(:appeal) { create(:appeal) }

      before do
        @new_acd.instance_variable_set(:@appeals, [appeal, nil])
        Rails.cache.fetch("case_distribution_ineligible_judges") { [{ sattyid: "1", id: "1" }] }
      end

      it "#ama_distributed_cases_tied_to_ineligible_judges raises an error if passed nil in array" do
        expect { @new_acd.send(:ama_distributed_cases_tied_to_ineligible_judges) }.to raise_error(NoMethodError)
      end

      it "#distributed_cases_tied_to_ineligible_judges raises an error if passed nil in array" do
        expect { @new_acd.send(:distributed_cases_tied_to_ineligible_judges) }.to raise_error(NoMethodError)
      end

      it "ama_statistics handles the errors from #ama_distributed_cases_tied_to_ineligible_judges
          and #distributed_cases_tied_to_ineligible_judges" do
        expect { @new_acd.send(:ama_statistics) }.not_to raise_error
      end
    end
  end
end
