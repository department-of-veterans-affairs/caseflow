class Reader::ApplicationController < ApplicationController
  before_action :verify_access, :verify_reader_feature_enabled

  def logo_name
    "Reader"
  end

  def logo_path
    reader_appeal_index_path
  end

  def set_application
    RequestStore.store[:application] = "reader"
  end

  def verify_reader_feature_enabled
    verify_feature_enabled(:reader)
  end

  def verify_access
    verify_authorized_roles("Reader")
  end
end
