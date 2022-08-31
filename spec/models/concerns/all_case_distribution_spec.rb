# frozen_string_literal: true

describe AllCaseDistribution, :all_dbs do
  class AllCaseDistributionTest
    include ActiveModel::Model
    include AllCaseDistribution

    attr_accessor :judge

    def batch_size
      9
    end
  end

  before(:all) do
    FeatureToggle.enable!(:priority_acd)
    FeatureToggle.enable!(:acd_distribute_all)
    @new_acd = AllCaseDistributionTest.new(judge: User.new)
  end

  # used to put {num} ambiguous objects into an array to mock the return array from requested_distribution
  def add_object_to_return_array(num)
    array = []
    num.times do
      array << Object.new
    end
    array
  end

  context "#requested_distribution" do
    # hash is set up to only use direct_review/evidence_submission so that legacy/hearing can be mocked
    # the total for each of these dockets needs to equal the batch_size above
    let(:nonpriority_count_hash) { { direct_review: 5, evidence_submission: 4 } }

    it "calls each method and returns the array of objects received from each method" do
      # method from distributing legacy appeals when :priority_acd enabled
      allow_any_instance_of(LegacyDocket).to receive(:distribute_nonpriority_appeals)
        .and_return([])

      # methods from distributing tied priority and non-priority appeals
      allow_any_instance_of(LegacyDocket).to receive(:distribute_appeals)
        .and_return([])

      allow_any_instance_of(HearingRequestDocket).to receive(:distribute_appeals)
        .and_return([])

      # returning {} from num_oldest_priority_appeals_by_docket will bypass
      # distribute_limited_priority_appeals_from_all_dockets not iterate over anything
      allow(@new_acd).to receive(:num_oldest_priority_appeals_by_docket)
        .and_return({})

      # distribute genpop nonpriority appeals from all dockets
      allow(@new_acd).to receive(:num_oldest_genpop_nonpriority_appeals_by_docket)
        .with(@new_acd.batch_size)
        .and_return(nonpriority_count_hash)

      allow_any_instance_of(DirectReviewDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: false, style: "request", limit: nonpriority_count_hash[:direct_review])
        .and_return(add_object_to_return_array(nonpriority_count_hash[:direct_review]))

      allow_any_instance_of(EvidenceSubmissionDocket).to receive(:distribute_appeals)
        .with(@new_acd, priority: false, style: "request", limit: nonpriority_count_hash[:evidence_submission])
        .and_return(add_object_to_return_array(nonpriority_count_hash[:evidence_submission]))

      # requested_distribution is private so .send is used to directly call it
      return_array = @new_acd.send :requested_distribution
      expect(return_array.count).to eq(9)
    end
  end
end
