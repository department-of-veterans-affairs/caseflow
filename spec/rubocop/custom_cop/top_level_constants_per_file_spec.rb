# frozen_string_literal: true

require "spec_helper"
require "rubocop"
require "rubocop/rspec/support"
require_relative "../../../.rubocop/custom_cop/top_level_constants_per_file"

describe RuboCop::CustomCop::TopLevelConstantsPerFile do
  include RuboCop::RSpec::ExpectOffense

  subject(:cop) { described_class.new(config) }
  let(:config) { RuboCop::Config.new }

  let(:message) do
    "Multiple top-level constants detected in one file. The autoloader expects one top-level constant per file."
  end

  context "when there is only one top-level class in file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        class SomeClass; end
      RUBY
    end
  end

  context "when there is only one top-level module in file" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        module SomeModule; end
      RUBY
    end
  end

  context "when there is only one top-level class/module in file, having one or more nested classes/modules" do
    it "does not register an offense" do
      expect_no_offenses(<<~RUBY)
        module SomeModule
          class FirstNestedClass; end
          class SecondNestedClass; end
        end
      RUBY
    end
  end

  context "when there are multiple top-level classes/modules in file" do
    it "registers an offense on the second one" do
      expect_offense(<<~RUBY)
        class FirstClass; end
        module SomeModule; end
        ^^^^^^^^^^^^^^^^^^^^^^ #{message}
        class SecondClass; end
      RUBY
    end
  end
end
