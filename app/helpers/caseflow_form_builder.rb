class CaseflowFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options = {})
    options[:maxwidth] ||= 45
    question_number = options.delete(:question_number)
    label = ("<strong>#{question_number}</strong> " + options.delete(:label)).html_safe
    disabled_class = options[:disabled] ? "cf-form-disabled" : ""

    @template.content_tag :div,
                          id: "#{question_number}-#{attribute.to_s.dasherize}",
                          class: "cf-form-textinput #{disabled_class}" do
      label(attribute, label) + super
    end
  end
end
