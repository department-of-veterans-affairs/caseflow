# frozen_string_literal: true

# This test can't be run as part of the Distribution model spec because the model initializes before
# the feature toggle is set and will never load ByDocketDateDistribution in a test environment. Also,
# we cannot test the negative of this expectation because once we initialize the Distribution class
# here, it will never load AutomaticCaseDistribution
RSpec.describe "Distribution concern module loading", :all_dbs do
  it "loads ByDocketDateDistribution if :acd_distribute_by_docket_date is enabled" do
    FeatureToggle.enable!(:acd_distribute_by_docket_date)
    dist = Distribution.new
    expect(dist.class.include?(ByDocketDateDistribution)).to eq true
  end
end
