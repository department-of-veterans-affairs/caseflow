def expect_main_menu_help_to_visit(path_part)
  expect(page.find_link("Help", visible: false)[:href]).to include(path_part)
end
