require "rails_helper"

describe CachedAttributes do
  class TestThing
    include CachedAttributes

    # ID is required to create a key to store the hash
    def id
      "AN_ID"
    end

    def rating
      TestThing.example_rating
    end
    cache_attribute :rating

    class << self
      attr_accessor :example_rating
    end
  end

  let(:model) { TestThing.new }

  context ".clear_cached_attrs!", focus: true do
    it "clears the cached attributes" do
      TestThing.example_rating = 10
      model.rating
      model.clear_cached_attrs!
      TestThing.example_rating = Random.rand
      expect(model.rating).to eq(TestThing.example_rating)
    end
  end

  context ".cache_attribute", focus: true do
    subject { model.rating }
    before do
      model.clear_cached_attrs!
      TestThing.example_rating = 10
    end

    context "when no cached value" do
      before { TestThing.example_rating = 9 }
      it { is_expected.to eq(9) }
    end

    context "when cached value" do
      before do
        model.rating
        TestThing.example_rating = 9
      end

      it { is_expected.to eq(10) }
    end
  end
end
