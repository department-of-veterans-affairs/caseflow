module FeatureHelper
  def find_table_cell(vacols_id, row_header)
    header = find(:xpath, "//thead/tr/th", text: row_header)
    header_index = /.*\[(\d+)\]$/.match(header.path)[1] # select out the last index
    find(:xpath, "//tbody/tr[@id='table-row-#{vacols_id}']/td[#{header_index}]")
  end

  # in the `options` hash...
  # required:
  #   `index` (the selection's position in the list) OR `text` (the value of the selection)
  # optional:
  #   `prompt` (the placeholder text in the dropdown) OR `name` (the dropdown class, like `.dropdown-[name]`
  #   `wait` (in seconds) so Capybara will wait longer than `Capybara.default_max_wait_time` before timing out
  def click_dropdown(options = {}, container = page)
    options = { index: nil, text: nil, prompt: nil, name: nil, wait: nil }.merge(options)
    dropdown = find_dropdown(options, container)
    selector = ""
    keyword_args = {}

    dropdown.click
    yield if block_given?

    keyword_args[:wait] = options[:wait] if options[:wait].present? && options[:wait] > 0

    if options[:text].present?
      selector = "div .Select-option"
      keyword_args[:text] = options[:text]
    elsif options[:index].present?
      selector = "div[id$='--option-#{options[:index]}']"
    end

    try_clicking_dropdown_menu_item(dropdown, selector, keyword_args)
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

  def find_dropdown(options, container)
    selector = ".Select-control"
    keyword_args = {}

    if options[:prompt].present?
      keyword_args[:text] = options[:prompt]
    elsif options[:name].present?
      selector = ".dropdown-#{options[:name]} .Select-control"
    end

    keyword_args[:wait] = options[:wait] if options[:wait].present? && options[:wait] > 0

    container.find(selector, **keyword_args)
  end

  # sometimes the dropdown menu hasn't appeared after the first click
  def try_clicking_dropdown_menu_item(dropdown, selector, keyword_args)
    tries = 3
    until dropdown_menu_visible?(dropdown) || tries <= 0
      dropdown.click
      tries -= 1
    end

    click_dropdown_menu_item(dropdown, selector, keyword_args)
  end

  def dropdown_menu_visible?(dropdown)
    dropdown.sibling(".Select-menu-outer")
  rescue Capybara::ElementNotFound
    false
  else
    true
  end

  def click_dropdown_menu_item(dropdown, selector, keyword_args)
    dropdown.sibling(".Select-menu-outer").find(selector, **keyword_args).click
  end

  def generate_text(length)
    charset = ("A".."Z").to_a.concat(("a".."z").to_a)
    Array.new(length) { charset.sample }.join
  end
end
