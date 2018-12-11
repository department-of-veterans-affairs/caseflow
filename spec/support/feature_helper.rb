module FeatureHelper
  def click_dropdown(options = {}, container = page)
    options = { index: nil, text: nil }.merge(options)
    dropdown = container.find(".Select-control")
    dropdown.click
    yield if block_given?
    if options[:text].present?
      dropdown.sibling(".Select-menu-outer").find("div .Select-option", text: options[:text]).click
    elsif options[:index].present?
      dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{options[:index]}']").click
    end
  end
end
