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
  end

  before(:each) do
    FeatureToggle.enable!(:priority_acd)
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
    @new_acd = ByDocketDateDistributionTest.new(judge: User.new)
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
        .with(@new_acd, @new_acd.batch_size)
        .and_return(priority_count_hash)

      expect_any_instance_of(LegacyDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:legacy])
        .and_return(add_object_to_return_array(priority_count_hash[:legacy]))

      expect_any_instance_of(DirectReviewDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:direct_review])
        .and_return(add_object_to_return_array(priority_count_hash[:direct_review]))

      expect_any_instance_of(EvidenceSubmissionDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:evidence_submission])
        .and_return(add_object_to_return_array(priority_count_hash[:evidence_submission]))

      expect_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: true, style: "push", limit: priority_count_hash[:hearing])
        .and_return(add_object_to_return_array(priority_count_hash[:hearing]))

      # requested_distribution is private so .send is used to directly call it
      return_array = @new_acd.send :priority_push_distribution, 12
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
      return_array = @new_acd.send :requested_distribution
      expect(return_array.count).to eq(@new_acd.batch_size)
    end
  end

  context "#num_oldest_priority_appeals_for_judge_by_docket" do
    it "returns an empty hash if provided num is zero" do
      return_value = @new_acd.send :num_oldest_priority_appeals_for_judge_by_docket, @new_acd, 0
    end

    it "calls each docket and sorts the return values if num > 0" do
      expect_any_instance_of(LegacyDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(DirectReviewDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(EvidenceSubmissionDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      expect_any_instance_of(HearingRequestDocket).to receive(:age_of_n_oldest_priority_appeals_available_to_judge)
        .with(@new_acd.judge, @new_acd.batch_size)
        .and_return(add_dates_to_date_array(@new_acd.batch_size))

      return_array = @new_acd.send(
        :num_oldest_priority_appeals_for_judge_by_docket,
        @new_acd,
        @new_acd.batch_size
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

      expect_any_instance_of(EvidenceSubmissionDocket).to receive(:age_of_n_oldest_nonpriority_appeals_available_to_judge)
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
      @new_acd.instance_variable_set(:@appeals, [])
    end

    it "returns a hash with keys" do
      statistics = @new_acd.send(:ama_statistics)

      expect(statistics).to include(:batch_size)
      expect(statistics).to include(:total_batch_size)
      expect(statistics).to include(:priority_target)
      expect(statistics).to include(:priority)
      expect(statistics).to include(:nonpriority)
      expect(statistics).to include(:algorithm)

      priority_stats = statistics[:priority]
      nonpriority_stats = statistics[:nonpriority]

      expect(priority_stats).to include(:count)
      expect(priority_stats).to include(:legacy_hearing_tied_to)
      expect(nonpriority_stats).to include(:count)
      expect(nonpriority_stats).to include(:legacy_hearing_tied_to)
      expect(nonpriority_stats).to include(:iterations)

      @new_acd.dockets.each_key do |sym|
        expect(priority_stats).to include(sym)
        expect(nonpriority_stats).to include(sym)
      end
    end
  end
end
