# frozen_string_literal: true

describe VbmsCommunicationPackage, :postgres do
  let(:package) do
    VbmsCommunicationPackage.new(
      file_number: "329780002",
      comm_package_name: "Test Package Name",
      vbms_uploaded_document: VbmsUploadedDocument.new(document_type: "Test Doc Type")
    )
  end

  it "is valid with valid attributes" do
    expect(package).to be_valid
  end

  it "is not valid without a filenumber" do
    package.filenumber = nil
    expect(package).to_not be_valid

    package.filenumber = ""
    expect(package).to_not be_valid
  end

  it "is not valid without a communication package name" do
    package.comm_package_name = nil
    expect(package).to_not be_valid

    package.comm_package_name = ""
    expect(package).to_not be_valid
  end

  it "is not valid if communication package name exceeds 255 characters" do
    package.comm_package_name = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    expect(package).to_not be_valid
  end

  it "is not valid without a user friendly communication package name" do
    package.comm_package_name = "(Test Package Name)"
    expect(package).to_not be_valid
  end
end
