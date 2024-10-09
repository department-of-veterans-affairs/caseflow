# frozen_string_literal: true

RSpec.describe "Zeitwerk" do
  it "eager loads all files without errors" do
    expect { Rails.application.eager_load! }.not_to raise_error
  end
end
