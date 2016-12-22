class CaseflowFormBuilder < ActionView::Helpers::FormBuilder
  def text_field(attribute, options = {})
    options[:maxlength] ||= 45
    options["aria-disabled"] = true if options[:readonly]

    wrapped_text_field(attribute, options, super(attribute, trim_options(options)))
  end

  def text_area(attribute, options = {})
    options[:rows] = 6
    options["aria-disabled"] = true if options[:readonly]

    @template.content_tag :div, id: question_id(options),
                                class: "cf-form-textarea" do
      question_label(attribute, options) + super(attribute, trim_options(options))
    end
  end

  def date_field(attribute, options = {})
    options["aria-disabled"] = true if options[:readonly]

    wrapped_text_field(attribute, options, super(attribute, trim_options(options)))
  end

  def radio_buttons_field(attribute, options = {})
    inline_class = options[:inline] ? "cf-form-radio-inline" : ""

    @template.content_tag :fieldset, id: question_id(options),
                                     class: "#{inline_class} cf-form-showhide-radio" do
      question_legend(options) + error_container + radio_button_options(attribute, options)
    end
  end

  def yes_no_field(attribute, options = {})
    options[:values] = %w(Yes No)
    options[:inline] = true
    radio_buttons_field(attribute, options)
  end

  def check_box_group(attributes, options = {})
    @template.content_tag :fieldset, id: question_id(options) do
      question_legend(options) + error_container + check_box_grid(attributes, options)
    end
  end

  private

  def question_id(options)
    "question#{options[:question_number]}#{options[:part]}"
  end

  def wrapped_text_field(attribute, options, input)
    readonly_class = options[:readonly] ? "cf-form-disabled" : ""

    @template.content_tag :div, id: question_id(options),
                                class: "cf-form-textinput #{readonly_class}" do
      question_label(attribute, options) + error_container + input
    end
  end

  def question_legend(options)
    @template.content_tag :legend, class: "question-label" do
      label_content(options)
    end
  end

  def question_label(attribute, options)
    label(attribute, label_content(options), class: "question-label")
  end

  def label_content(options)
    if options[:secondary]
      "<strong></strong><em>#{options[:label]}</em>".html_safe
    else
      "<strong>#{options[:question_number]}</strong> #{options[:label]}".html_safe
    end
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

  def check_box_grid(attributes, options)
    @template.content_tag(:div, class: "usa-grid-full cf-form-checkboxes") do
      attributes.in_groups(3, false).map do |column_attributes|
        check_box_column(column_attributes, options)
      end.join("\n").html_safe
    end
  end

  def check_box_column(attributes, _options)
    @template.content_tag :div, class: "usa-width-one-third" do
      attributes.map do |attribute|
        @template.content_tag :div, class: "cf-form-checkbox" do
          check_box(attribute[:attribute], include_hidden: false) +
            label(attribute[:attribute], attribute[:label])
        end
      end.join("\n").html_safe
    end
  end

  def trim_options(options)
    options.except(:question_number, :label, :secondary, :part)
  end

  def error_container
    @template.content_tag(:span, class: "usa-input-error-message") {}
  end
end
