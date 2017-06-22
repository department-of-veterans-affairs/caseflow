class Reader::ApplicationController < ApplicationController
  def logo_name
    "Reader"
  end

  def logo_path
    reader_appeal_index_path
  end

  def set_application
    RequestStore.store[:application] = "reader"
  end
end
