module FeatureHelper
  def find_table_cell(vacols_id, row_header)
    header = find(:xpath, "//thead/tr/th", text: row_header)
    header_index = /.*\[(\d+)\]$/.match(header.path)[1] # select out the last index
    find(:xpath, "//tbody/tr[@id='table-row-#{vacols_id}']/td[#{header_index}]")
  end

  def click_dropdown(options = {}, container = page)
    options = { prompt: nil, index: nil, text: nil, name: nil, wait: nil }.merge(options)
    dropdown = expect_or_wait_and_find_dropdown(options, container)

    dropdown.click
    yield if block_given?

    if options[:text].present?
      dropdown.sibling(".Select-menu-outer").find("div .Select-option", text: options[:text], wait: options[:wait])
        .click
    elsif options[:index].present?
      dropdown.sibling(".Select-menu-outer").find("div[id$='--option-#{options[:index]}']", wait: options[:wait]).click
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

  def expect_or_wait_and_find_dropdown(options, container)
    selector = ".Select-control"
    keyword_args = {}

    if options[:prompt].present?
      keyword_args = { text: options[:prompt] }
    elsif options[:name].present?
      selector = ".dropdown-#{options[:name]} .Select-control"
    end

    if options[:wait].present? && options[:wait] > 0
      keyword_args[:wait] = options[:wait]
    else
      expect(container).to have_selector(selector, **keyword_args)
    end

    container.find(selector, **keyword_args)
  end

  def generate_text(length)
    charset = ("A".."Z").to_a.concat(("a".."z").to_a)
    Array.new(length) { charset.sample }.join
  end
end
