# frozen_string_literal: true

describe VbmsCommunicationPackage, :postgres do
  let(:package) do
    VbmsCommunicationPackage.new(
      file_number: "329780002",
      comm_package_name: "Test Package Name",
      vbms_uploaded_document: class_double(VbmsUploadedDocument)
    )
  end

  it "is valid with valid attributes" do
    expect(package).to be_valid
  end

  it "is not valid with nil filenumber" do
    package.filenumber = nil
    expect(package).to_not be_valid
  end

  it "is not valid with empty string as filenumber" do
    package.filenumber = ""
    expect(package).to_not be_valid
  end

  it "is not valid with nil communication package name" do
    package.comm_package_name = nil
    expect(package).to_not be_valid
  end

  it "is not valid with empty string as communication package name" do
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

  it "is not valid without an associated VbmsUploadedDocument" do
    package.vbms_uploaded_document = nil
    expect(package).to_not be_valid
  end
end
