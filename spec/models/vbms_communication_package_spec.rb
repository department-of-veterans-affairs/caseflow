# frozen_string_literal: true

describe VbmsCommunicationPackage, :postgres do
  let(:package) do
    VbmsCommunicationPackage.new(
      file_number: "329780002",
      comm_package_name: "test package name",
      vbms_uploaded_document: class_double(VbmsUploadedDocument)
    )
  end

  it "is valid with valid attributes" do
    expect(package).to be_valid
  end

  it "is not valid without a filenumber" do
    package.filenumber = nil
    expect(package).to_not be_valid
  end

  it "is not valid without a communication package name" do
    package.comm_package_name = nil
    expect(package).to_not be_valid
  end

  it "is not valid if communication package name exceeds 255 characters" do
    invalid_package_name = ""
    256.times { invalid_package_name << "x" }
    package.comm_package_name = invalid_package_name
    expect(package).to_not be_valid
  end

  it "is not valid without a user friendly communication package name" do
    package.comm_package_name = "(test package name with parentheses)"
    expect(package).to_not be_valid
  end

  it "is not valid without an associated VbmsUploadedDocument" do
    package.vbms_uploaded_document = nil
    expect(package).to_not be_valid
  end
end
