# frozen_string_literal: true

# Ensure that all STI models are eager loaded, even when eager loading is disabled for the environment.
#   Why? Single Table Inheritance doesn't play well with lazy loading: Active Record has to be aware of STI hierarchies
#   to work correctly, but, when lazy loading, classes are only loaded only on demand.
#   For example, the class method `.descendants` will only return subclasses that have already been loaded into
#   mememory. So for STI classes leveraging this method, all subclasses will need to have been loaded already.
#
# See https://guides.rubyonrails.org/autoloading_and_reloading_constants.html#single-table-inheritance
#
# This test should be skipped if eager loading is enabled.
describe "STI Models", unless: Rails.application.config.eager_load do
  specify "are preloaded even when eager loading is disabled" do
    # Find preloaded STI classes (before eager loading)
    sti_class_names = find_sti_classes.map(&:name)

    # Find all expected STI classes (after eager loading)
    Rails.application.eager_load!
    expected_sti_class_names = find_sti_classes.map(&:name)

    # Assert that preloaded STI classes include all expected STI classes
    expect(sti_class_names).to eq(expected_sti_class_names)
  end

  def find_sti_classes
    ApplicationRecord.descendants.each_with_object([]) do |model, memo|
      next if model.abstract_class?
      next unless model.column_names.include?(model.inheritance_column)

      memo << model
    end
  end
end
