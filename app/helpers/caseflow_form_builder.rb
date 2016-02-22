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

    label_content = ("<strong>#{options[:question_number]}</strong> " + options[:label]).html_safe
    label(attribute, label_content, class: required_class)
  end

  def trim_options(options)
    options.except(:question_number, :required, :label)
  end
end
