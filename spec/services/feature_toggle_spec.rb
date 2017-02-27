describe FeatureToggle do
  let(:user1) { User.new(regional_office: "RO03") }
  let(:user2) { User.new(regional_office: "RO07") }

  before :each do
    FeatureToggle.client.flushall
  end

  context ".enable!" do
    context "for everyone" do
      subject { FeatureToggle.enable!(:search) }

      it "feature is enabled for everyone" do
        subject
        expect(FeatureToggle.enabled?(:search, user1)).to eq true
        expect(FeatureToggle.enabled?(:search, user2)).to eq true
      end
    end

    context "for a set of regional_offices" do
      subject { FeatureToggle.enable!(:test, regional_offices: %w(RO01 RO02 RO03)) }

      it "feature is enabled for users who belong to the regional offices" do
        subject
        expect(FeatureToggle.enabled?(:test, user1)).to eq true
        expect(FeatureToggle.enabled?(:test, user2)).to eq false
      end

      it "enable for more users" do
        subject
        FeatureToggle.enable!(:test, regional_offices: ["RO07"])
        expect(FeatureToggle.enabled?(:test, user1)).to eq true
        expect(FeatureToggle.enabled?(:test, user2)).to eq true
      end
    end
  end

  context ".disable!" do
    context "globally" do
      before do
        FeatureToggle.enable!(:search)
      end
      subject { FeatureToggle.disable!(:search) }

      it "feature is disabled for everyone" do
        subject
        expect(FeatureToggle.enabled?(:search, user1)).to eq false
        expect(FeatureToggle.enabled?(:search, user2)).to eq false
      end
    end

    context "for a set of regional offices" do
      before do
        FeatureToggle.enable!(:test, regional_offices: %w(RO07 RO03))
      end
      subject { FeatureToggle.disable!(:test, regional_offices: ["RO03"]) }

      it "users who belong to the regional offices can no longer access the feature" do
        subject
        expect(FeatureToggle.enabled?(:test, user1)).to eq false
        expect(FeatureToggle.enabled?(:test, user2)).to eq true
      end
    end

    context "when regional_offices becomes an empty array" do
      before do
        FeatureToggle.enable!(:test, regional_offices: %w(RO03 RO02 RO09))
      end
      subject { FeatureToggle.disable!(:test, regional_offices: %w(RO03 RO02 RO09)) }

      it "feature becomes enabled for everyone" do
        subject
        expect(FeatureToggle.enabled?(:test, user1)).to eq true
        expect(FeatureToggle.enabled?(:test, user2)).to eq true
      end

      it "feature can be disabled globally" do
        subject
        FeatureToggle.disable!(:test)
        expect(FeatureToggle.enabled?(:test, user1)).to eq false
        expect(FeatureToggle.enabled?(:test, user2)).to eq false
      end
    end

    context "when sending an empty array" do
      before do
        FeatureToggle.enable!(:test, regional_offices: %w(RO03 RO02 RO09))
      end
      subject { FeatureToggle.disable!(:test, regional_offices: []) }

      it "no regional offices are disabled" do
        subject
        expect(FeatureToggle.details_for(:test)[:regional_offices]).to eq %w(RO03 RO02 RO09)
      end
    end

    context "when sending incorrect regional offices" do
      before do
        FeatureToggle.enable!(:test, regional_offices: %w(RO03 RO02 RO09))
      end
      subject { FeatureToggle.disable!(:test, regional_offices: ["RO01"]) }

      it "no regional offices are disabled" do
        subject
        expect(FeatureToggle.details_for(:test)[:regional_offices]).to eq %w(RO03 RO02 RO09)
      end
    end
  end

  context ".features" do

    context "when features exist" do
      before do
        FeatureToggle.enable!(:test)
        FeatureToggle.enable!(:test)
        FeatureToggle.enable!(:search)
      end
      subject { FeatureToggle.features.sort }

      it { is_expected.to eq [:search, :test] }
    end

    context "when features do not exist" do
      subject { FeatureToggle.features }

      it { is_expected.to eq [] }
    end
  end

  context ".details_for" do

    subject { FeatureToggle.details_for(:banana) }

    context "when enabled globally" do
      before do
        FeatureToggle.enable!(:banana)
      end
      it { is_expected.to be {} }
    end

    context "when not enabled" do
      it { is_expected.to be nil }
    end

    context "when enabled for a list of regional offices" do
      before do
        FeatureToggle.enable!(:banana, regional_offices: %w(RO03 RO02 RO09))
      end
      it { is_expected.to eq(regional_offices: %w(RO03 RO02 RO09)) }
    end
  end

  context ".enabled?" do
    context "when enabled for everyone" do
      before do
        FeatureToggle.enable!(:search)
      end
      subject { FeatureToggle.enabled?(:search, user1) }

      it { is_expected.to eq true }
    end

    context "when a feature does not exist in redis" do
      subject { FeatureToggle.enabled?(:foo, user1) }

      it { is_expected.to eq false }
    end

    context "when enabled for a set of regional_offices" do
      subject { FeatureToggle.enabled?(:search, user) }

      before do
        FeatureToggle.enable!(:search, regional_offices: %w(RO01 RO02 RO03))
      end

      context "if a user is associated with a regional office" do
        let(:user) { User.new(regional_office: "RO02") }
        it { is_expected.to eq true }
      end

      context "if a user is not associated with a regional office" do
        let(:user) { User.new(regional_office: "RO09") }
        it { is_expected.to eq false }
      end
    end
  end
end
