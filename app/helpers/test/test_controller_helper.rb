# frozen_string_literal: true

module Test::TestControllerHelper
  class << self
    def form_values
      {
        feature_toggles_available: find_features.map { |key, value| { name: key, default_status: value } },
        functions_available: find_functions,
        all_csum_roles: find_roles,
        all_organizations: find_orgs
      }
    end

    def test_users
      return [] unless ApplicationController.dependencies_faked?

      User.all
    end

    def features_list
      return [] unless ApplicationController.dependencies_faked?

      FeatureToggle.features
    end

    def ep_types
      %w[full partial none all]
    end

    def user_session(id_param, session)
      (id_param == "me") ? session : nil
    end

    def find_features
      all_features = AllFeatureToggles.new.call.flatten.uniq.sort
      all_features.map! do |feature|
        sym_feature = feature.split(",")[0].to_sym
        [sym_feature, FeatureToggle.enabled?(sym_feature)]
      end
      all_features.to_h
    end

    def find_functions
      Functions.functions.sort
    end

    def find_roles
      User.all.pluck(:roles).flatten.uniq.compact.sort
    end

    def find_orgs
      Organization.pluck(:name).compact.sort
    end
  end
end
