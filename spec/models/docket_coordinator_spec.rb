describe DocketCoordinator do
  before do
    FeatureToggle.enable!(:test_facols)
    FeatureToggle.enable!(:ama_auto_case_distribution)
    Timecop.freeze(Time.utc(2020, 4, 1, 12, 0, 0))
  end

  after do
    FeatureToggle.disable!(:test_facols)
    FeatureToggle.disable!(:ama_auto_case_distribution)
  end
end
