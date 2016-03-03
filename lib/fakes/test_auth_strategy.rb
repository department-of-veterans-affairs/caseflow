require "omniauth/strategies/developer"
require "omniauth/form"

class OmniAuth::Strategies::TestAuthStrategy < OmniAuth::Strategies::Developer
  # custom form rendering
  def request_phase
    form = OmniAuth::Form.new(title: "Test VA Saml", url: callback_path)
    options.fields.each do |field|
      form.text_field field.to_s.capitalize.tr("_", " "), field.to_s
    end
    form.button "Sign In"
    form.to_response
  end

  option :fields, [:email]
end
