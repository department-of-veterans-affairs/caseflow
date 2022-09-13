# frozen_string_literal: true

FactoryBot.define do
  initial_value = Veteran.all.map(&:file_number).max

  sequence :veteran_file_number, initial_value do |n|
    format("%<n>09d", n: n)
  end
end
