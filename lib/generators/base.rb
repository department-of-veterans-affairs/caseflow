# frozen_string_literal: true

# Base class for a generator.
#
# The purpose of generators is to easily setup data for testing.
# They are used in a similar way to FactoryGirl, but are also used
# for instrumenting faked dependecies.
#
# They are useful for:
# - Setting up default boilerplate data like ids
# - Setting up and connecting the appropriate data in Fakes
# - Containing complex data fixtures
#
# Each Generator class must implement the `.build(attrs)` method
# which must return an unsaved ActiveRecord object. Generators will
# get the `create(attrs)` method for free by extending Generators::Base
module Generators::Base
  def generate_external_id(seed = nil)
    return (seed % 10_000_000).to_s if seed

    RANDOM.rand(10_000_000).to_s
  end

  def generate_first_name(seed = nil)
    fnames = %w[George John Thomas James Andrew Martin Susan Barack Grace Anne]
    return fnames[seed % fnames.length] if seed

    fnames[RANDOM.rand(fnames.length)]
  end

  def generate_last_name(seed = nil)
    lnames = %w[Washington King Jefferson Anthony Madison Jackson VanBuren Merica]
    return lnames[seed % lnames.length] if seed

    lnames[RANDOM.rand(lnames.length)]
  end

  def build(*)
    fail "#{self.class.name} must implement .build(attrs)"
  end

  def create(attrs = {})
    build(attrs).tap(&:save!)
  end

  RANDOM = Random.new(0)
end
