describe FeatureToggle do

  let(:user1) { User.new(regional_office: "RO03") }
  let(:user2) { User.new(regional_office: "RO07") }

  before :each do
    FeatureToggle.client.flushall
  end

  it "should enable a feature" do
    FeatureToggle.enable!(:test)
    # should enable only once
    FeatureToggle.enable!(:test)
    FeatureToggle.enable!(:search)
    expect(FeatureToggle.features.sort).to eq %w(search test)
    expect(FeatureToggle.enabled?(:search, user1)).to eq true
  end

  it "should disable a feature" do
    FeatureToggle.enable!(:test)
    FeatureToggle.enable!(:search)
    FeatureToggle.disable!(:test)
    expect(FeatureToggle.features).to eq %w(search)
    expect(FeatureToggle.enabled?(:test, user1)).to eq false
    expect(FeatureToggle.enabled?(:search, user1)).to eq true
  end

  it "should return details for a feature" do
    FeatureToggle.enable!(:test)
    expect(FeatureToggle.details_for(:test)).to be {}
    FeatureToggle.enable!(:test, regional_offices: ["RO08", "RO01"])
    expect(FeatureToggle.details_for(:test).keys).to eq ["regional_offices"]
  end

  it "should enable/disable a feature for multiple regional offices" do
    FeatureToggle.enable!(:test, regional_offices: ["RO01", "RO02", "RO03"])
    expect(FeatureToggle.details_for(:test)["regional_offices"].sort).to eq ["RO01", "RO02", "RO03"]
    expect(FeatureToggle.enabled?(:test, user1)).to eq true
    expect(FeatureToggle.enabled?(:test, user2)).to eq false

    # disable RO03
    FeatureToggle.disable!(:test, regional_offices: ["RO03"])
    expect(FeatureToggle.details_for(:test)["regional_offices"].sort).to eq ["RO01", "RO02"]
    expect(FeatureToggle.enabled?(:test, user1)).to eq false
    expect(FeatureToggle.enabled?(:test, user2)).to eq false

    # enable RO07
    FeatureToggle.enable!(:test, regional_offices: ["RO07"])
    expect(FeatureToggle.details_for(:test)["regional_offices"].sort).to eq ["RO01", "RO02", "RO07"]
    expect(FeatureToggle.enabled?(:test, user1)).to eq false
    expect(FeatureToggle.enabled?(:test, user2)).to eq true

    # feature doesn't exist
    expect(FeatureToggle.enabled?(:foo, user2)).to eq false

    # disable the entire feature
    FeatureToggle.disable!(:test)
    expect(FeatureToggle.details_for(:test)).to eq nil
    expect(FeatureToggle.enabled?(:test, user1)).to eq false
    expect(FeatureToggle.enabled?(:test, user2)).to eq false
  end
end
