# frozen_string_literal: true

describe VbmsCommunicationPackage, :postgres do
  let(:package) do
    VbmsCommunicationPackage.new(
      file_number: "329780002",
      comm_package_name: "test package name",
      document_referenced: [1],
      vbms_uploaded_document: VbmsUploadedDocument.new
    )
  end

  it "is valid with valid attributes" do
    expect(package).to be_valid
  end

  it "is not valid without a filenumber" do
    package.file_number = nil
    expect(package).to_not be_valid
  end

  it "is not valid without a communication package name" do
    package.comm_package_name = nil
    expect(package).to_not be_valid
  end

  it "is not valid if communication package name exceeds 255 characters" do
    package.comm_package_name = "x" * 256
    expect(package).to_not be_valid
  end

  it "is not valid without a user friendly communication package name" do
    package.comm_package_name = "(test package name with parentheses)"
    expect(package).to_not be_valid
  end

  it "is not valid without a document referenced" do
    package.document_referenced = nil
    expect(package).to_not be_valid
  end

  it "is not valid with less than one document referenced" do
    package.document_referenced = []
    expect(package).to_not be_valid
  end

  it "is not valid without an associated VbmsUploadedDocument" do
    package.vbms_uploaded_document = nil
    expect(package).to_not be_valid
  end
end
