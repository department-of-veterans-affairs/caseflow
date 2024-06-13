# frozen_string_literal: true

context "api/docs/v3/ama_issues.yaml" do
  let(:spec) do
    YAML.safe_load(File.read(File.join(Rails.root, "app/controllers/swagger/v3/ama_issues.yaml")))
  end

  it "exists and is valid yaml" do
    expect { spec }.not_to raise_error
  end

  it "has veteran participant id mentioned in parameters" do
    parameters = spec.dig(
      "paths",
      "/find_by_veteran/{veteran_participant_id}",
      "get",
      "parameters"
    )
    expect(parameters.first["name"]).to eq "veteran_participant_id"
  end

  it "has page mentioned in parameters" do
    parameters = spec.dig(
      "paths",
      "/find_by_veteran/{veteran_participant_id}",
      "get",
      "parameters"
    )
    expect(parameters.second["name"]).to eq "page"
    expect(parameters.second["schema"]["type"]).to eq "integer"
  end

  it "has the status codes accounted for" do
    responzez = spec.dig(
      "paths",
      "/find_by_veteran/{veteran_participant_id}",
      "get",
      "responses"
    )
    expect(responzez.map(&:first)).to match_array %w[200 401 404 500 501]
  end

  it "has VeteranParticipantId schema" do
    vpi = spec.dig(
      "components",
      "schemas",
      "VeteranParticipantId"
    )
    expect(vpi.empty?).to eq false
  end

  it "has Errors schema" do
    er = spec.dig(
      "components",
      "schemas",
      "Errors"
    )
    expect(er.empty?).to eq false
  end

  it "has RequestIssue schema" do
    ri = spec.dig(
      "components",
      "schemas",
      "RequestIssue"
    )
    expect(ri.empty?).to eq false
  end

  it "has RequestIssue schema" do
    di = spec.dig(
      "components",
      "schemas",
      "DecisionIssue"
    )
    expect(di.empty?).to eq false
  end
end
