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

  context ".z?" do
    it { expect(v.z?()).to be true }
    it { expect { v.z?() }.to raise_error(ArgumentError) }
  end
end
