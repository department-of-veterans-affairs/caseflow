# frozen_string_literal: true

# Shared examples for AMA and legacy appeals

shared_examples "toggle overtime" do
  before { FeatureToggle.enable!(:overtime_revamp) }

  after { FeatureToggle.disable!(:overtime_revamp) }

  it "updates #overtime?" do
    expect(appeal.overtime?).to be(false)

    appeal.overtime = true
    expect(appeal.overtime?).to be(true)

    appeal.overtime = false
    expect(appeal.overtime?).to be(false)
  end
end
