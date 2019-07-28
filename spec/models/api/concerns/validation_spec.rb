# frozen_string_literal: true

require "rails_helper"

describe Api::Validation do
  let(:v) { Class.new { include Api::Validation }.new }

  context ".int?" do
    it { expect(v.int?(123)).to be true }
    it { expect { v.int?(123.99) }.to raise_error(ArgumentError) }
    it { expect { v.int?("123") }.to raise_error(ArgumentError) }
    it { expect(v.int?("123", exception: nil)).to be false }
    it { expect { v.int?("123", exception: NoMethodError) }.to raise_error(NoMethodError) }
    it { expect { v.int?(nil) }.to raise_error(ArgumentError) }
    it { expect { v.int?(false) }.to raise_error(ArgumentError) }
    it { expect { v.int?([]) }.to raise_error(ArgumentError) }
    it { expect { v.int?({}) }.to raise_error(ArgumentError) }
    it { expect { v.int? }.to raise_error(ArgumentError) }
  end

  context ".int_or_int_string?" do
    it { expect(v.int_or_int_string?(123)).to be true }
    it { expect { v.int_or_int_string?(123.99) }.to raise_error(ArgumentError) }
    it { expect(v.int_or_int_string?("123")).to be true }
    it { expect { v.int_or_int_string?("123.99") }.to raise_error(ArgumentError) }
    it { expect { v.int_or_int_string?(nil) }.to raise_error(ArgumentError) }
    it { expect { v.int_or_int_string?(false) }.to raise_error(ArgumentError) }
    it { expect { v.int_or_int_string?([]) }.to raise_error(ArgumentError) }
    it { expect { v.int_or_int_string?({}) }.to raise_error(ArgumentError) }
    it { expect { v.int_or_int_string?({}, exception: NoMethodError) }.to raise_error(NoMethodError) }
    it { expect { v.int_or_int_string? }.to raise_error(ArgumentError) }
  end

  context ".present?" do
    it { expect { v.present?(nil) }.to raise_error(ArgumentError) }
    it { expect { v.present?(false) }.to raise_error(ArgumentError) }
    it { expect(v.present?(0)).to be true }
    it { expect { v.present?("") }.to raise_error(ArgumentError) }
    it { expect { v.present?("  ") }.to raise_error(ArgumentError) }
    it { expect { v.present?([]) }.to raise_error(ArgumentError) }
    it { expect(v.present?([nil])).to be true }
    it { expect { v.present?({}) }.to raise_error(ArgumentError) }
    it { expect(v.present?({}, exception: nil)).to be false }
    it { expect(v.present?(true)).to be true }
    it { expect(v.present?(22)).to be true }
    it { expect(v.present?("cat")).to be true }
    it { expect(v.present?([1, 2])).to be true }
    it { expect(v.present?(a: 1)).to be true }
  end

  context ".nullable_array?" do
    it { expect(v.nullable_array?(nil)).to be true }
    it { expect { v.nullable_array?(false) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_array?(0) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_array?("") }.to raise_error(ArgumentError) }
    it { expect { v.nullable_array?("  ") }.to raise_error(ArgumentError) }
    it { expect(v.nullable_array?([])).to be true }
    it { expect(v.nullable_array?([nil])).to be true }
    it { expect { v.nullable_array?({}) }.to raise_error(ArgumentError) }
    it { expect(v.nullable_array?({}, exception: nil)).to be false }
    it { expect { v.nullable_array?(true) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_array?(22) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_array?("cat") }.to raise_error(ArgumentError) }
    it { expect(v.nullable_array?([1, 2])).to be true }
    it { expect { v.nullable_array?(a: 1) }.to raise_error(ArgumentError) }
  end

  context ".string?" do
    it { expect { v.string?(nil) }.to raise_error(ArgumentError) }
    it { expect { v.string?(true) }.to raise_error(ArgumentError) }
    it { expect { v.string?(false) }.to raise_error(ArgumentError) }
    it { expect { v.string?(0) }.to raise_error(ArgumentError) }
    it { expect { v.string?(55) }.to raise_error(ArgumentError) }
    it { expect(v.string?("")).to be true }
    it { expect(v.string?("  ")).to be true }
    it { expect(v.string?("cat")).to be true }
    it { expect { v.string?([]) }.to raise_error(ArgumentError) }
    it { expect { v.string?([nil]) }.to raise_error(ArgumentError) }
    it { expect { v.string?([1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.string?({}) }.to raise_error(ArgumentError) }
    it { expect { v.string?(a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.string?(0, exception: nil)).to be false }
  end

  context ".nullable_string?" do
    it { expect(v.nullable_string?(nil)).to be true }
    it { expect { v.nullable_string?(true) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?(false) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?(0) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?(55) }.to raise_error(ArgumentError) }
    it { expect(v.nullable_string?("")).to be true }
    it { expect(v.nullable_string?("  ")).to be true }
    it { expect(v.nullable_string?("cat")).to be true }
    it { expect { v.nullable_string?([]) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?([nil]) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?([1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?({}) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_string?(a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.nullable_string?(0, exception: nil)).to be false }
  end

  context ".date_string?" do
    it { expect { v.date_string?(nil) }.to raise_error(ArgumentError) }
    it { expect(v.date_string?(nil, exception: nil)).to be false }
    it { expect { v.date_string?(true) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?(false) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?(0) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?(55) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?("") }.to raise_error(ArgumentError) }
    it { expect { v.date_string?("  ") }.to raise_error(ArgumentError) }
    it { expect { v.date_string?("cat") }.to raise_error(ArgumentError) }
    it { expect { v.date_string?([]) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?([nil]) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?([1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?({}) }.to raise_error(ArgumentError) }
    it { expect { v.date_string?(a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.date_string?("2019-01-01")).to be true }
    it { expect(v.date_string?("2020-01-01")).to be true }
    it { expect(v.date_string?("4020-01-01")).to be true }
    it { expect(v.date_string?("1919-01-01")).to be true }
    it { expect(v.date_string?("123456789-01-01")).to be true }
    it { expect(v.date_string?("  2019-01-01")).to be true }
    it { expect(v.date_string?("  2019  - 01-01  ")).to be true }
    it { expect { v.date_string?("2019-14-01") }.to raise_error(ArgumentError) } # not a month
    it { expect { v.date_string?("2019-02-29") }.to raise_error(ArgumentError) } # not a leap year
  end

  context ".nullable_date_string?" do
    it { expect(v.nullable_date_string?(nil)).to be true }
    it { expect { v.nullable_date_string?(true) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?(false) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?(0) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?(55) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?("") }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?("  ") }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?("cat") }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?([]) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?([nil]) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?([1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?({}) }.to raise_error(ArgumentError) }
    it { expect { v.nullable_date_string?(a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.nullable_date_string?({ a: 1 }, exception: nil)).to be false }
    it { expect(v.nullable_date_string?("2019-01-01")).to be true }
    it { expect(v.nullable_date_string?("2020-01-01")).to be true }
    it { expect(v.nullable_date_string?("4020-01-01")).to be true }
    it { expect(v.nullable_date_string?("1919-01-01")).to be true }
    it { expect(v.nullable_date_string?("123456789-01-01")).to be true }
    it { expect(v.nullable_date_string?("  2019-01-01")).to be true }
    it { expect(v.nullable_date_string?("  2019  - 01-01  ")).to be true }
    it { expect { v.nullable_date_string?("2019-14-01") }.to raise_error(ArgumentError) } # not a month
    it { expect { v.nullable_date_string?("2019-02-29") }.to raise_error(ArgumentError) } # not a leap year
  end

  context ".true?" do
    it { expect { v.true?(nil) }.to raise_error(ArgumentError) }
    it { expect(v.true?(true)).to be true }
    it { expect { v.true?(false) }.to raise_error(ArgumentError) }
    it { expect { v.true?(0) }.to raise_error(ArgumentError) }
    it { expect { v.true?(55) }.to raise_error(ArgumentError) }
    it { expect { v.true?("") }.to raise_error(ArgumentError) }
    it { expect { v.true?("  ") }.to raise_error(ArgumentError) }
    it { expect { v.true?("cat") }.to raise_error(ArgumentError) }
    it { expect { v.true?([]) }.to raise_error(ArgumentError) }
    it { expect { v.true?([nil]) }.to raise_error(ArgumentError) }
    it { expect { v.true?([1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.true?({}) }.to raise_error(ArgumentError) }
    it { expect { v.true?(a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.true?(0, exception: nil)).to be false }
  end
end
