# frozen_string_literal: true

require "rails_helper"

describe Api::V3::Concerns::Validation do
  let(:v) { Class.new { include Api::V3::Concerns::Validation }.new }

  context ".hash?" do
    it { expect { v.send(:hash?, 123) }.to raise_error(ArgumentError) }
    it { expect { v.send(:hash?, "123") }.to raise_error(ArgumentError) }
    it { expect(v.send(:hash?, "123", exception: nil)).to be false }
    it { expect { v.send(:hash?, "123", exception: NoMethodError) }.to raise_error(NoMethodError) }
    it { expect { v.send(:hash?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:hash?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:hash?, []) }.to raise_error(ArgumentError) }
    it { expect(v.send(:hash?, {})).to be true }
    it { expect { v.send(:hash?) }.to raise_error(ArgumentError) }
  end

  context ".int?" do
    it { expect(v.send(:int?, 123)).to be true }
    it { expect { v.send(:int?, 123.99) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int?, "123") }.to raise_error(ArgumentError) }
    it { expect(v.send(:int?, "123", exception: nil)).to be false }
    it { expect { v.send(:int?, "123", exception: NoMethodError) }.to raise_error(NoMethodError) }
    it { expect { v.send(:int?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int?) }.to raise_error(ArgumentError) }
  end

  context ".int_or_int_string?" do
    it { expect(v.send(:int_or_int_string?, 123)).to be true }
    it { expect { v.send(:int_or_int_string?, 123.99) }.to raise_error(ArgumentError) }
    it { expect(v.send(:int_or_int_string?, "123")).to be true }
    it { expect { v.send(:int_or_int_string?, "123.99") }.to raise_error(ArgumentError) }
    it { expect { v.send(:int_or_int_string?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int_or_int_string?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int_or_int_string?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int_or_int_string?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:int_or_int_string?, {}, exception: NoMethodError) }.to raise_error(NoMethodError) }
    it { expect { v.send(:int_or_int_string?) }.to raise_error(ArgumentError) }
  end

  context ".present?" do
    it { expect { v.send(:present?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:present?, false) }.to raise_error(ArgumentError) }
    it { expect(v.send(:present?, 0)).to be true }
    it { expect { v.send(:present?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:present?, "  ") }.to raise_error(ArgumentError) }
    it { expect { v.send(:present?, []) }.to raise_error(ArgumentError) }
    it { expect(v.send(:present?, [nil])).to be true }
    it { expect { v.send(:present?, {}) }.to raise_error(ArgumentError) }
    it { expect(v.send(:present?, {}, exception: nil)).to be false }
    it { expect(v.send(:present?, true)).to be true }
    it { expect(v.send(:present?, 22)).to be true }
    it { expect(v.send(:present?, "cat")).to be true }
    it { expect(v.send(:present?, [1, 2])).to be true }
    it { expect(v.send(:present?, a: 1)).to be true }
    it { expect { v.send(:present?) }.to raise_error(ArgumentError) }
  end

  context ".array?" do
    it { expect { v.send(:array?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?, "  ") }.to raise_error(ArgumentError) }
    it { expect(v.send(:array?, [])).to be true }
    it { expect(v.send(:array?, [nil])).to be true }
    it { expect { v.send(:array?, {}) }.to raise_error(ArgumentError) }
    it { expect(v.send(:array?, {}, exception: nil)).to be false }
    it { expect { v.send(:array?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?, 22) }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?, "cat") }.to raise_error(ArgumentError) }
    it { expect(v.send(:array?, [1, 2])).to be true }
    it { expect { v.send(:array?, a: 1) }.to raise_error(ArgumentError) }
    it { expect { v.send(:array?) }.to raise_error(ArgumentError) }
  end

  context ".nullable_array?" do
    it { expect(v.send(:nullable_array?, nil)).to be true }
    it { expect { v.send(:nullable_array?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_array?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_array?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_array?, "  ") }.to raise_error(ArgumentError) }
    it { expect(v.send(:nullable_array?, [])).to be true }
    it { expect(v.send(:nullable_array?, [nil])).to be true }
    it { expect { v.send(:nullable_array?, {}) }.to raise_error(ArgumentError) }
    it { expect(v.send(:nullable_array?, {}, exception: nil)).to be false }
    it { expect { v.send(:nullable_array?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_array?, 22) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_array?, "cat") }.to raise_error(ArgumentError) }
    it { expect(v.send(:nullable_array?, [1, 2])).to be true }
    it { expect { v.send(:nullable_array?, a: 1) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_array?) }.to raise_error(ArgumentError) }
  end

  context ".string?" do
    it { expect { v.send(:string?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, 55) }.to raise_error(ArgumentError) }
    it { expect(v.send(:string?, "")).to be true }
    it { expect(v.send(:string?, "  ")).to be true }
    it { expect(v.send(:string?, "cat")).to be true }
    it { expect { v.send(:string?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:string?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:string?, 0, exception: nil)).to be false }
    it { expect { v.send(:string?) }.to raise_error(ArgumentError) }
  end

  context ".nullable_string?" do
    it { expect(v.send(:nullable_string?, nil)).to be true }
    it { expect { v.send(:nullable_string?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, 55) }.to raise_error(ArgumentError) }
    it { expect(v.send(:nullable_string?, "")).to be true }
    it { expect(v.send(:nullable_string?, "  ")).to be true }
    it { expect(v.send(:nullable_string?, "cat")).to be true }
    it { expect { v.send(:nullable_string?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_string?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:nullable_string?, 0, exception: nil)).to be false }
    it { expect { v.send(:nullable_string?) }.to raise_error(ArgumentError) }
  end

  context ".date_string?" do
    it { expect { v.send(:date_string?, nil) }.to raise_error(ArgumentError) }
    it { expect(v.send(:date_string?, nil, exception: nil)).to be false }
    it { expect { v.send(:date_string?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, 55) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, "  ") }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, "cat") }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:date_string?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:date_string?, "2019-01-01")).to be true }
    it { expect(v.send(:date_string?, "2020-01-01")).to be true }
    it { expect(v.send(:date_string?, "4020-01-01")).to be true }
    it { expect(v.send(:date_string?, "1919-01-01")).to be true }
    it { expect(v.send(:date_string?, "123456789-01-01")).to be true }
    it { expect(v.send(:date_string?, "  2019-01-01")).to be true }
    it { expect(v.send(:date_string?, "  2019  - 01-01  ")).to be true }
    it { expect { v.send(:date_string?, "2019-14-01") }.to raise_error(ArgumentError) } # not a month
    it { expect { v.send(:date_string?, "2019-02-29") }.to raise_error(ArgumentError) } # not a leap year
    it { expect { v.send(:date_string?) }.to raise_error(ArgumentError) }
  end

  context ".nullable_date_string?" do
    it { expect(v.send(:nullable_date_string?, nil)).to be true }
    it { expect { v.send(:nullable_date_string?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, 55) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, "  ") }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, "cat") }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:nullable_date_string?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:nullable_date_string?, { a: 1 }, exception: nil)).to be false }
    it { expect(v.send(:nullable_date_string?, "2019-01-01")).to be true }
    it { expect(v.send(:nullable_date_string?, "2020-01-01")).to be true }
    it { expect(v.send(:nullable_date_string?, "4020-01-01")).to be true }
    it { expect(v.send(:nullable_date_string?, "1919-01-01")).to be true }
    it { expect(v.send(:nullable_date_string?, "123456789-01-01")).to be true }
    it { expect(v.send(:nullable_date_string?, "  2019-01-01")).to be true }
    it { expect(v.send(:nullable_date_string?, "  2019  - 01-01  ")).to be true }
    it { expect { v.send(:nullable_date_string?, "2019-14-01") }.to raise_error(ArgumentError) } # not a month
    it { expect { v.send(:nullable_date_string?, "2019-02-29") }.to raise_error(ArgumentError) } # not a leap year
    it { expect { v.send(:nullable_date_string?) }.to raise_error(ArgumentError) }
  end

  context ".boolean?" do
    it { expect { v.send(:boolean?, nil) }.to raise_error(ArgumentError) }
    it { expect(v.send(:boolean?, true)).to be true }
    it { expect(v.send(:boolean?, false)).to be true }
    it { expect { v.send(:boolean?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, 55) }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, "  ") }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, "cat") }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:boolean?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:boolean?, 0, exception: nil)).to be false }
    it { expect { v.send(:boolean?) }.to raise_error(ArgumentError) }
  end

  context ".true?" do
    it { expect { v.send(:true?, nil) }.to raise_error(ArgumentError) }
    it { expect(v.send(:true?, true)).to be true }
    it { expect { v.send(:true?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, 55) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, "  ") }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, "cat") }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:true?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:true?, 0, exception: nil)).to be false }
    it { expect { v.send(:true?) }.to raise_error(ArgumentError) }
  end

  context ".benefit_type?" do
    [nil, true, false, 0, 55, "", " ", "cat", [], [nil], [1, 2], {}, { a: 1 }].each do |input|
      it do
        expect do
          v.send(:benefit_type?, input, "compensation")
        end.to raise_error(ArgumentError)
      end
    end

    %w[
      nca compensation
    ].each do |type|
      it do
        expect(v.send(:benefit_type?, type)).to be true
      end
    end

    [
      "   nca",
      "compensation "
    ].each do |type|
      it do
        expect do
          v.send(:benefit_type?, type)
        end.to raise_error(ArgumentError)
      end
    end

    it { expect(v.send(:benefit_type?, "ice cream", exception: nil)).to be false }
    it { expect { v.send(:benefit_type?) }.to raise_error(ArgumentError) }
  end

  context ".nullable_benefit_type?" do
    [nil, true, false, 0, 55, "", " ", "cat", [], [nil], [1, 2], {}, { a: 1 }].each do |input|
      it do
        expect do
          v.send(:nullable_benefit_type?, input, "compensation")
        end.to raise_error(ArgumentError)
      end
    end

    %w[
      nca compensation
    ].each do |type|
      it do
        expect(v.send(:nullable_benefit_type?, type)).to be true
      end
    end

    [
      "   nca",
      "compensation "
    ].each do |type|
      it do
        expect do
          v.send(:nullable_benefit_type?, type)
        end.to raise_error(ArgumentError)
      end
    end

    it { expect(v.send(:nullable_benefit_type?, "ice cream", exception: nil)).to be false }
    it { expect { v.send(:nullable_benefit_type?) }.to raise_error(ArgumentError) }
  end

  context ".nonrating_issue_category_for_benefit_type?" do
    [nil, true, false, 0, 55, "", " ", "cat", [], [nil], [1, 2], {}, { a: 1 }].each do |input|
      it do
        expect do
          v.send(:nonrating_issue_category_for_benefit_type?, input, "compensation")
        end.to raise_error(ArgumentError)
      end
    end

    [
      ["Entitlement | Reserves/National Guard", "nca"],
      %w[Apportionment compensation]
    ].each do |(cat, ben)|
      it do
        expect(v.send(:nonrating_issue_category_for_benefit_type?, cat, ben)).to be true
      end
    end

    [
      ["   Entitlement | Reserves/National Guard", "nca"],
      %w[Apportionment loan_guaranty]
    ].each do |(cat, ben)|
      it do
        expect do
          v.send(:nonrating_issue_category_for_benefit_type?, cat, ben)
        end.to raise_error(ArgumentError)
      end
    end

    it { expect(v.send(:nonrating_issue_category_for_benefit_type?, "a", "b", exception: nil)).to be false }
    it { expect { v.send(:nonrating_issue_category_for_benefit_type?) }.to raise_error(ArgumentError) }
  end

  context ".nullable_nonrating_issue_category_for_benefit_type?" do
    [true, false, 0, 55, "", " ", "cat", [], [nil], [1, 2], {}, { a: 1 }].each do |input|
      it do
        expect do
          v.send(:nullable_nonrating_issue_category_for_benefit_type?, input, "compensation")
        end.to raise_error(ArgumentError)
      end
    end

    [
      ["Entitlement | Reserves/National Guard", "nca"],
      %w[Apportionment compensation],
      [nil, "compensation"],
      [nil, "ice cream"]
    ].each do |(cat, ben)|
      it do
        expect(v.send(:nullable_nonrating_issue_category_for_benefit_type?, cat, ben)).to be true
      end
    end

    [
      ["   Entitlement | Reserves/National Guard", "nca"],
      %w[Apportionment loan_guaranty]
    ].each do |(cat, ben)|
      it do
        expect do
          v.send(:nullable_nonrating_issue_category_for_benefit_type?, cat, ben)
        end.to raise_error(ArgumentError)
      end
    end

    it { expect { v.send(:nullable_nonrating_issue_category_for_benefit_type?) }.to raise_error(ArgumentError) }
  end

  context ".payee_code?" do
    it { expect { v.send(:payee_code?, nil) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, true) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, false) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, 0) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, 55) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, "") }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, "  ") }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, "cat") }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, []) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, [nil]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, [1, 2]) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, {}) }.to raise_error(ArgumentError) }
    it { expect { v.send(:payee_code?, a: 1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:payee_code?, "01")).to be true }
    it { expect(v.send(:payee_code?, "11")).to be true }
    it { expect { v.send(:payee_code?, 0o1) }.to raise_error(ArgumentError) }
    it { expect(v.send(:payee_code?, 11, exception: nil)).to be false }
    it { expect { v.send(:payee_code?) }.to raise_error(ArgumentError) }
  end

  context ".any_present?" do
    [
      [nil],
      [nil, false],
      [" "],
      [" ", []]
    ].each do |args|
      it do
        expect do
          v.send(:any_present?, *args)
        end.to raise_error(ArgumentError)
      end
    end

    [
      [1],
      [nil, true]
    ].each do |args|
      it do
        expect(v.send(:any_present?, *args)).to be true
      end
    end

    it { expect { v.send(:any_present?) }.to raise_error(ArgumentError) }
  end

  context ".hash_keys_are_within_this_set?" do
    [
      [{ a: 1, b: 2, c: 3, d: 4 }, { keys: [:a, :b, :c] }]
    ].each do |args|
      it do
        expect do
          v.send(:hash_keys_are_within_this_set?, *args)
        end.to raise_error(ArgumentError)
      end
    end

    [
      [{ a: 1, b: 2 }, { keys: [:a, :b] }],
      [{ a: 1 }, { keys: [:a, :b, :c] }],
      [{}, { keys: [:a, :b, :c] }]
    ].each do |args|
      it do
        expect(v.send(:hash_keys_are_within_this_set?, *args)).to be true
      end
    end

    it { expect { v.send(:hash_keys_are_within_this_set?) }.to raise_error(ArgumentError) }
  end

  context ".hash_has_at_least_these_keys?" do
    [
      [{ a: 1, b: 2 }, { keys: [:a, :b, :c] }],
      [{}, { keys: [:a, :b, :c] }]
    ].each do |args|
      it do
        expect do
          v.send(:hash_has_at_least_these_keys?, *args)
        end.to raise_error(ArgumentError)
      end
    end

    [
      [{ a: 1, b: 2 }, { keys: [:a, :b] }],
      [{ a: 1, b: 2, c: 3, d: 4 }, { keys: [:a, :b] }]
    ].each do |args|
      it do
        expect(v.send(:hash_has_at_least_these_keys?, *args)).to be true
      end
    end

    it { expect { v.send(:hash_has_at_least_these_keys?) }.to raise_error(ArgumentError) }
  end

  context ".these_are_the_hash_keys?" do
    [
      [{ a: 1, b: 2 }, { keys: [:a, :b, :c] }],
      [{ a: 1, b: 2, c: 3, d: 4 }, { keys: [:a, :b] }],
      [{}, { keys: [:a, :b, :c] }]
    ].each do |args|
      it do
        expect do
          v.send(:these_are_the_hash_keys?, *args)
        end.to raise_error(ArgumentError)
      end
    end

    [
      [{}, { keys: [] }],
      [{ a: 1, b: 2 }, { keys: [:a, :b] }]
    ].each do |args|
      it do
        expect(v.send(:these_are_the_hash_keys?, *args)).to be true
      end
    end

    it { expect { v.send(:these_are_the_hash_keys?) }.to raise_error(ArgumentError) }
  end
end
