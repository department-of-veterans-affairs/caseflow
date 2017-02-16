describe FeatureToggle do
  before :each do
    FeatureToggle.client.flushall
  end

  it "should enable a feature" do
    FeatureToggle.enable_feature(:test)
    FeatureToggle.enable_feature(:search)
    expect(FeatureToggle.client.sismember(FeatureToggle::FEATURES, :test)).to eq true
    expect(FeatureToggle.features).to eq %w(test search)
  end

  it "should return error if feature is already enabled" do
    FeatureToggle.enable_feature(:test)
    expect { FeatureToggle.enable_feature(:test) }.to raise_error(FeatureToggle::FeatureIsAlreadyEnabledError)
  end

  it "should disable a feature" do
    FeatureToggle.enable_feature(:test)
    FeatureToggle.disable_feature(:test)
    expect(FeatureToggle.client.sismember(FeatureToggle::FEATURES, :test)).to eq false
  end

  it "should enable/disable a feature for a regional office" do
    FeatureToggle.enable_feature(:stats)
    FeatureToggle.enable_group(:stats, "RO01")
    FeatureToggle.enable_group(:stats, "RO02")
    FeatureToggle.enable_group(:stats, "RO03")
    FeatureToggle.disable_group(:stats, "RO02")
    expect(FeatureToggle.list_groups(:stats).sort).to eq %w(RO01 RO03)
  end

  it "should return error if feature is not enabled" do
    expect { FeatureToggle.disable_feature(:absent) }.to raise_error
    [:enable_group, :disable_group].each do |m|
      expect { FeatureToggle.send(m, :absent, "RO03") }.to raise_error(FeatureToggle::FeatureIsNotEnabledError)
    end
    [:list_groups, :clear_all_groups].each do |m|
      expect { FeatureToggle.send(m, :absent) }.to raise_error(FeatureToggle::FeatureIsNotEnabledError)
    end
  end

  it "should check if a feature is enabled/disabled for a regional office" do
    FeatureToggle.enable_feature(:search)
    FeatureToggle.enable_group(:search, "RO01")
    expect(FeatureToggle.enabled_for_group?(:search, "RO01")).to eq true
    expect(FeatureToggle.enabled_for_group?(:search, "RO03")).to eq false
    expect(FeatureToggle.disabled_for_group?(:search, "RO03")).to eq true
    expect(FeatureToggle.disabled_for_group?(:thing, "RO01")).to eq true
  end

  it "should clear all regional offices for a feature" do
    FeatureToggle.enable_feature(:stats)
    FeatureToggle.enable_group(:stats, "RO01")
    FeatureToggle.enable_group(:stats, "RO02")
    FeatureToggle.clear_all_groups(:stats)
    expect(FeatureToggle.list_groups(:stats)).to eq []
  end
end
