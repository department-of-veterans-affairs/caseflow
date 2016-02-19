class CaseflowFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options = {})
    options[:maxwidth] ||= 45

    wrapped_text_field(attribute, options, super(attribute, trim_options(options)))
  end

  def text_area(attribute, options = {})
    options[:rows] = 3

    @template.content_tag :div,
                          id: question_id(attribute, options),
                          class: "cf-form-textarea" do
      question_label(attribute, options) + super(attribute, trim_options(options))
    end
  end

  def date_field(attribute, options = {})
    wrapped_text_field(attribute, options, super(attribute, trim_options(options)))
  end

  def radio_buttons_field(attribute, options = {})
    required_class = options[:required] ? "required" : ""

    legend = @template.content_tag :legend, class: required_class do
      label_content(options) +
      @template.content_tag(:span, class: "usa-input-error-message") {}
    end

    @template.content_tag :fieldset, class: "cf-form-showhide-radio" do
      legend + radio_button_options(attribute, options)
    end
  end

  private

  def question_id(_attribute, options)
    "question#{options[:question_number]}"
  end

  def wrapped_text_field(attribute, options, input)
    readonly_class = options[:readonly] ? "cf-form-disabled" : ""

    @template.content_tag :div,
                          id: question_id(attribute, options),
                          class: "cf-form-textinput #{readonly_class}" do
      question_label(attribute, options) + input
    end
  end

  def question_label(attribute, options)
    required_class = options[:required] ? "required" : ""
    label(attribute, label_content(options), class: required_class)
  end

  def label_content(options)
    ("<strong>#{options[:question_number]}</strong> " + options[:label]).html_safe
  end

  def radio_button_options(attribute, options = {})
    @template.content_tag :div, class: "cf-form-radio-options" do
      options[:values].map do |value|
        radio_button_option(attribute, value)
      end.join("\n").html_safe
    end
  end

  def radio_button_option(attribute, value)
    @template.content_tag :div, class: "cf-form-radio-option" do
      radio_button(attribute, value) + label(attribute, value, value: value)
    end
  end

  def trim_options(options)
    options.except(:question_number, :required, :label)
  end
end
