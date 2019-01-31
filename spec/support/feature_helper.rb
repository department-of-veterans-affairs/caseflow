module FeatureHelper
  def click_dropdown(options = {}, container = page) # rubocop:disable Metrics/PerceivedComplexity
    options = { prompt: nil, index: nil, text: nil, name: nil }.merge(options)
    dropdown = if options[:prompt].present?
                 container.find(".Select-control", text: options[:prompt])
               elsif options[:name].present?
                 container.find(".dropdown-#{options[:name]} .Select-control")
               else
                 container.find(".Select-control")
               end

    dropdown.click
    yield if block_given?

    if options[:text].present?
      dropdown.sibling(".Select-menu-outer").find("div .Select-option", text: options[:text]).click
    elsif options[:index].present?
      dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{options[:index]}']").click
    end
  end

  def dropdown_selected_value(container = page)
    container&.find(".Select-control .Select-value")&.text
  rescue Capybara::ElementNotFound
    ""
  end

  def generate_words(n_words)
    Array.new(n_words).map do
      word_length = [rand(12), 3].max
      generate_text(word_length)
    end.join(" ")
  end

  def step(title)
    puts "  __step: #{title}" if ENV["SHOW_STEPS"]
    yield
  end

  def xstep(title)
    puts "  __skipped step: #{title}" if ENV["SHOW_STEPS"]
  end

  private

  def generate_text(length)
    charset = ("A".."Z").to_a.concat(("a".."z").to_a)
    Array.new(length) { charset.sample }.join
  end
end
