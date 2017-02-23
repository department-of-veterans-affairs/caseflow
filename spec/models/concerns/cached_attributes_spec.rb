require "rails_helper"

describe CachedAttributes do
  class TestThing
    include CachedAttributes

    # ID is required to create a key to store the hash
    def id
      "AN_ID"
    end

    def rating
      TestThing.rating
    end
    cache_attribute :rating

    class << self
      attr_accessor :rating
    end
  end

  let(:model) { TestThing.new }

  context ".cache_attribute" do
    subject { model.rating }
    before do
      model.clear_cached_attrs!
      TestThing.rating = 10
    end

    context "when no cached value" do
      before { TestThing.rating = 9 }
      it { is_expected.to eq(9) }
    end

    context "when cached value" do
      before do
        model.rating
        TestThing.rating = 9
      end

      it { is_expected.to eq(10) }
    end
  end
end
