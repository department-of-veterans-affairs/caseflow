# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength
module FeatureHelper
  def find_table_cell(vacols_id, row_header)
    header = find(:xpath, "//thead/tr/th", text: row_header)
    header_index = /.*\[(\d+)\]$/.match(header.path)[1] # select out the last index
    find(:xpath, "//tbody/tr[@id='table-row-#{vacols_id}']/td[#{header_index}]")
  end

  def click_queue_switcher(text)
    find(".cf-dropdown-trigger", text: COPY::CASE_LIST_TABLE_QUEUE_DROPDOWN_LABEL).click
    click_on text
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

    dropdown_options = dropdown_click_and_get_options(dropdown)
    yield if block_given?

    keyword_args[:wait] = options[:wait] if options[:wait].present? && options[:wait] > 0

    if options[:text].present?
      selector = "div .cf-select__option"
      keyword_args[:text] = options[:text]
    elsif options[:index].present?
      selector = "div[id$='-option-#{options[:index]}']"
    end

    click_dropdown_menu_item(dropdown, selector, keyword_args)

    dropdown_options
  end

  def dropdown_selected_value(container = page)
    container&.find(".cf-select .cf-select__single-value")&.text
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

  def safe_click(selector)
    scroll_to(selector)
    page.first(selector).click
  end

  def click_label(label_for)
    safe_click("label[for='#{label_for}']")
  end

  def get_computed_styles(selector, style_key)
    sanitized_selector = selector.gsub("'", "\\\\'")

    page.evaluate_script <<-EOS
      function() {
        var elem = document.querySelector('#{sanitized_selector}');
        if (!elem) {
          // It would be nice to throw an actual error but I am not sure Capybara will
          // process that well.
          return 'query selector `#{sanitized_selector}` did not match any elements';
        }
        return window.getComputedStyle(elem)['#{style_key}'];
      }();
    EOS
  end

  def be_titled(title)
    have_xpath("//title[contains(.,'#{title}')]", visible: false)
  end

  def hang
    puts "Hanging the test indefinitely so you can debug in the browser."
    sleep(10_000)
  end

  private

  def dropdown_click_and_get_options(dropdown)
    dropdown.click unless dropdown_menu_visible?(dropdown)
    dropdown.sibling(".cf-select__menu")&.text&.split("\n") || []
  end

  def find_dropdown(options, container)
    selector = ".cf-select__control"
    keyword_args = {}

    if options[:prompt].present?
      keyword_args[:text] = options[:prompt]
    elsif options[:name].present?
      selector = ".dropdown-#{options[:name]} .cf-select__control"
    end

    keyword_args[:wait] = options[:wait] if options[:wait].present? && options[:wait] > 0

    container.find(selector, **keyword_args)
  end

  def dropdown_menu_visible?(dropdown)
    dropdown.sibling(".cf-select__menu", wait: false)
  rescue Capybara::ElementNotFound
    false
  else
    true
  end

  def click_dropdown_menu_item(dropdown, selector, keyword_args)
    dropdown.sibling(".cf-select__menu").find(selector, **keyword_args).click
  end

  def generate_text(length)
    charset = ("A".."Z").to_a.concat(("a".."z").to_a)
    Array.new(length) { charset.sample }.join
  end
end
# rubocop:enable Metrics/ModuleLength
