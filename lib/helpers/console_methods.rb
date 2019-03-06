# frozen_string_literal: true

module ConsoleMethods
  def define_user
    RequestStore[:current_user] = OpenStruct.new(station_id: ENV["STATION_ID"],
                                                 css_id: ENV["CSS_ID"],
                                                 regional_office: ENV["RO_ID"])
  end
end
