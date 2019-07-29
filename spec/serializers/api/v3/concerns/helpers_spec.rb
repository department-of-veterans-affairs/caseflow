# frozen_string_literal: true

require "rails_helper"

describe Api::V3::Concerns::Helpers do
  let(:helped_object) { Class.new { include Api::V3::Concerns::Helpers }.new }

  context ".to_float" do
    it { expect(helped_object.to_float(999)).to eq(999) }
    it { expect(helped_object.to_float(999.01)).to eq(999.01) }
    it { expect(helped_object.to_float(nil)).to eq(nil) }
    it { expect(helped_object.to_float(false)).to eq(nil) }
    it { expect(helped_object.to_float("abc")).to eq(nil) }
    it { expect(helped_object.to_float("999")).to eq(999) }
    it { expect(helped_object.to_float(" 999")).to eq(999) }
    it { expect(helped_object.to_float("999abc")).to eq(nil) }
    it { expect(helped_object.to_float("0999")).to eq(999) } # doesn't read it as octal
    it { expect(helped_object.to_float("0777")).to eq(777) }
    it { expect(helped_object.to_float("0777.12")).to eq(777.12) }
    it { expect(helped_object.to_float("0xf")).to eq(15) }
    it { expect(helped_object.to_float("0xF")).to eq(15) }
    it { expect(helped_object.to_float("999.01")).to eq(999.01) }
    it { expect(helped_object.to_float("999e3")).to eq(999_000) }
    it { expect(helped_object.to_float("999E3")).to eq(999_000) }
    it { expect(helped_object.to_float("999E-3")).to eq(0.999) }
    it { expect(helped_object.to_float("999e-3")).to eq(0.999) }
    it { expect(helped_object.to_float("999E+3")).to eq(999_000) }
    it { expect(helped_object.to_float("999e+3")).to eq(999_000) }
    it { expect { helped_object.to_float }.to raise_error(ArgumentError) }
  end

  context ".to_int" do
    it { expect(helped_object.to_int(999)).to eq(999) }
    it { expect(helped_object.to_int(999.01)).to eq(999) }
    it { expect(helped_object.to_int(nil)).to eq(nil) }
    it { expect(helped_object.to_int(false)).to eq(nil) }
    it { expect(helped_object.to_int("abc")).to eq(nil) }
    it { expect(helped_object.to_int("999")).to eq(999) }
    it { expect(helped_object.to_int(" 999")).to eq(999) }
    it { expect(helped_object.to_int("999abc")).to eq(nil) }
    it { expect(helped_object.to_int("0999")).to eq(nil) } # octal
    it { expect(helped_object.to_int("0777")).to eq(511) }
    it { expect(helped_object.to_int("0xf")).to eq(15) }
    it { expect(helped_object.to_int(0o777)).to eq(511) }
    it { expect(helped_object.to_int(0xf)).to eq(15) }
    it { expect(helped_object.to_int("999.01")).to eq(999) }
    it { expect(helped_object.to_int("999e3")).to eq(999_000) }
    it { expect(helped_object.to_int("999E3")).to eq(999_000) }
    it { expect(helped_object.to_int("999E-3")).to eq(0) }
    it { expect(helped_object.to_int("999e-3")).to eq(0) }
    it { expect(helped_object.to_int("999E+3")).to eq(999_000) }
    it { expect(helped_object.to_int("999e+3")).to eq(999_000) }
    it { expect { helped_object.to_int }.to raise_error(ArgumentError) }
  end

  context ".join_present" do
    it { expect(helped_object.join_present("a", "b", "c")).to eq("a b c") }
    it { expect(helped_object.join_present("a", nil, "c")).to eq("a c") }
    it { expect(helped_object.join_present("a", false, "c")).to eq("a c") }
    it { expect(helped_object.join_present("a", "", "c")).to eq("a c") }
    it { expect(helped_object.join_present("a", "  ", "c")).to eq("a c") }
    it { expect(helped_object.join_present("a", [], "c")).to eq("a c") }
    it { expect(helped_object.join_present(nil, "b", "c")).to eq("b c") }
    it { expect(helped_object.join_present(false, "b", "c")).to eq("b c") }
    it { expect(helped_object.join_present("", "b", "c")).to eq("b c") }
    it { expect(helped_object.join_present("  ", "b", "c")).to eq("b c") }
    it { expect(helped_object.join_present([], "b", "c")).to eq("b c") }
    it { expect(helped_object.join_present).to eq("") }
  end

  context ".missing_keys" do
    it { expect(helped_object.missing_keys({ a: 1, b: 2 }, expected_keys: [:a, :b, :c, :d])).to eq([:c, :d]) }
    it { expect(helped_object.missing_keys({}, expected_keys: [:a, :b, :c, :d])).to eq([:a, :b, :c, :d]) }
    it { expect(helped_object.missing_keys({}, expected_keys: [])).to eq([]) }
    it { expect(helped_object.missing_keys({ a: 1, b: 2 }, expected_keys: [])).to eq([]) }
    it { expect { helped_object.missing_keys([], expected_keys: [:a, :b, :c, :d]) }.to raise_error(StandardError) }
    it { expect { helped_object.missing_keys(nil, expected_keys: [:a, :b, :c]) }.to raise_error(StandardError) }
    it { expect { helped_object.missing_keys({ a: 1, b: 2 }, expected_keys: nil) }.to raise_error(NoMethodError) }
    it { expect(helped_object.missing_keys({ a: 1, b: 2 }, expected_keys: {})).to eq([]) }
    it { expect(helped_object.missing_keys({ a: 1 }, expected_keys: { a: 1, b: 2 })).to eq([:b]) }
  end

  context ".extra_keys" do
    it { expect(helped_object.extra_keys({ a: 1, b: 2 }, expected_keys: [:a, :b, :c, :d])).to eq([]) }
    it { expect(helped_object.extra_keys({ a: 1, b: 2, c: 3 }, expected_keys: [:a])).to eq([:b, :c]) }
    it { expect(helped_object.extra_keys({ a: 1, b: 2, c: 3 }, expected_keys: [])).to eq([:a, :b, :c]) }
    it { expect(helped_object.extra_keys({}, expected_keys: [:a, :b, :c, :d])).to eq([]) }
    it { expect(helped_object.extra_keys({}, expected_keys: [])).to eq([]) }
    it { expect { helped_object.extra_keys([], expected_keys: [:a, :b, :c, :d]) }.to raise_error(StandardError) }
    it { expect { helped_object.extra_keys(nil, expected_keys: [:a, :b, :c]) }.to raise_error(StandardError) }
    it { expect { helped_object.extra_keys({ a: 1, b: 2 }, expected_keys: nil) }.to raise_error(NoMethodError) }
    it { expect(helped_object.extra_keys({ a: 1, b: 2 }, expected_keys: {})).to eq([:a, :b]) }
    it { expect(helped_object.extra_keys({ a: 1 }, expected_keys: { a: 1, b: 2 })).to eq([]) }
  end
end
