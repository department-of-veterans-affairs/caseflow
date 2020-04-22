module CssIdConcern
  extend ActiveSupport::Concern

  # could also detect positive_integer?(params[:user_id]) here and map to CSS_ID in to_valid_cssid to simplify `user`
  def invalid_css_id?(css_id)
    css_id =~ /[a-z]/
  end

  def to_valid_css_id(css_id)
    css_id&.upcase
  end
end
