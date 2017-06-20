class Reader::ApplicationController < ApplicationController
  def logo_name
    "Reader"
  end

  def logo_path
    reader_appeal_index_path
  end
end
