require 'spec_helper'
require 'base64'
require 'nokogiri'

describe Akami do
  let(:wsse) { Akami.wsse }

  it "contains the namespace for WS Security Secext" do
    expect(Akami::WSSE::WSE_NAMESPACE).to eq(
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    )
  end

  it "contains the namespace for WS Security Utility" do
    expect(Akami::WSSE::WSU_NAMESPACE).to eq(
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    )
  end

  it "contains the namespace for the PasswordText type" do
    expect(Akami::WSSE::PASSWORD_TEXT_URI).to eq(
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
    )
  end

  it "contains the namespace for the PasswordDigest type" do
    expect(Akami::WSSE::PASSWORD_DIGEST_URI).to eq(
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
    )
  end

  it "contains the namespace for Base64 Encoding type" do 
    expect(Akami::WSSE::BASE64_URI).to eq( 
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"
    )
  end

  describe "#credentials" do
    it "sets the username" do
      wsse.credentials "username", "password"
      expect(wsse.username).to eq("username")
    end

    it "sets the password" do
      wsse.credentials "username", "password"
      expect(wsse.password).to eq("password")
    end

    it "defaults to set digest to false" do
      wsse.credentials "username", "password"
      expect(wsse).not_to be_digest
    end

    it "sets digest to true if specified" do
      wsse.credentials "username", "password", :digest
      expect(wsse).to be_digest
    end
  end

  describe "#username" do
    it "sets the username" do
      wsse.username = "username"
      expect(wsse.username).to eq("username")
    end
  end

  describe "#password" do
    it "sets the password" do
      wsse.password = "password"
      expect(wsse.password).to eq("password")
    end
  end

  describe "#digest" do
    it "defaults to false" do
      expect(wsse).not_to be_digest
    end

    it "specifies whether to use digest auth" do
      wsse.digest = true
      expect(wsse).to be_digest
    end
  end

  describe "#to_xml" do
    context "with no credentials" do
      it "returns an empty String" do
        expect(wsse.to_xml).to eq("")
      end
    end

    context "with only a username" do
      before { wsse.username = "username" }

      it "returns an empty String" do
        expect(wsse.to_xml).to eq("")
      end
    end

    context "with only a password" do
      before { wsse.password = "password" }

      it "returns an empty String" do
        expect(wsse.to_xml).to eq("")
      end
    end

    context "with credentials" do
      before { wsse.credentials "username", "password" }

      it "contains a wsse:Security tag" do
        namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
        expect(wsse.to_xml).to include("<wsse:Security xmlns:wsse=\"#{namespace}\">")
      end

      it "contains a wsu:Id attribute" do
        expect(wsse.to_xml).to include('<wsse:UsernameToken wsu:Id="UsernameToken-1"')
      end

      it "increments the wsu:Id attribute count" do
        expect(wsse.to_xml).to include('<wsse:UsernameToken wsu:Id="UsernameToken-1"')
        expect(wsse.to_xml).to include('<wsse:UsernameToken wsu:Id="UsernameToken-2"')
      end

      it "contains the WSE and WSU namespaces" do
        expect(wsse.to_xml).to include(Akami::WSSE::WSE_NAMESPACE, Akami::WSSE::WSU_NAMESPACE)
      end

      it "contains the username and password" do
        expect(wsse.to_xml).to include("username", "password")
      end

      it "does not contain a wsse:Nonce tag" do
        expect(wsse.to_xml).not_to match(/<wsse:Nonce.*>.*<\/wsse:Nonce>/)
      end

      it "does not contain a wsu:Created tag" do
        expect(wsse.to_xml).not_to match(/<wsu:Created>.*<\/wsu:Created>/)
      end

      it "contains the PasswordText type attribute" do
        expect(wsse.to_xml).to include(Akami::WSSE::PASSWORD_TEXT_URI)
      end
    end

    context "with credentials and digest auth" do
      before { wsse.credentials "username", "password", :digest }

      it "contains the WSE and WSU namespaces" do
        expect(wsse.to_xml).to include(Akami::WSSE::WSE_NAMESPACE, Akami::WSSE::WSU_NAMESPACE)
      end

      it "contains the username" do
        expect(wsse.to_xml).to include("username")
      end

      it "does not contain the (original) password" do
        expect(wsse.to_xml).not_to include("password")
      end

      it "contains the Nonce base64 type attribute" do
        expect(wsse.to_xml).to include(Akami::WSSE::BASE64_URI)
      end

      it "contains a wsu:Created tag" do
        created_at = Time.now
        Timecop.freeze created_at do
          expect(wsse.to_xml).to include("<wsu:Created>#{created_at.utc.xmlschema}</wsu:Created>")
        end
      end

      it "contains the PasswordDigest type attribute" do
        expect(wsse.to_xml).to include(Akami::WSSE::PASSWORD_DIGEST_URI)
      end

      it "should reset the nonce every time" do
        created_at = Time.now
        Timecop.freeze created_at do
          nonce_regexp = /<wsse:Nonce.*>([^<]+)<\/wsse:Nonce>/
          nonce_first = Base64.decode64(nonce_regexp.match(wsse.to_xml)[1])
          nonce_second = Base64.decode64(nonce_regexp.match(wsse.to_xml)[1])
          expect(nonce_first).not_to eq(nonce_second)
        end
      end

      it "has contains a properly hashed password" do
        xml_header = Nokogiri::XML(wsse.to_xml)
        xml_header.remove_namespaces!
        nonce = Base64.decode64(xml_header.xpath('//Nonce').first.content)
        created_at = xml_header.xpath('//Created').first.content
        password_hash = Base64.decode64(xml_header.xpath('//Password').first.content)
        expect(password_hash).to eq(Digest::SHA1.digest((nonce + created_at + "password")))
      end
    end

    context "with #timestamp set to true" do
      before { wsse.timestamp = true }

      it "contains a wsse:Timestamp node" do
        expect(wsse.to_xml).to include('<wsu:Timestamp wsu:Id="Timestamp-1" ' +
          'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">')
      end

      it "contains a wsu:Created node defaulting to Time.now" do
        created_at = Time.now
        Timecop.freeze created_at do
          expect(wsse.to_xml).to include("<wsu:Created>#{created_at.utc.xmlschema}</wsu:Created>")
        end
      end

      it "contains a wsu:Expires node defaulting to Time.now + 60 seconds" do
        created_at = Time.now
        Timecop.freeze created_at do
          expect(wsse.to_xml).to include("<wsu:Expires>#{(created_at + 60).utc.xmlschema}</wsu:Expires>")
        end
      end
    end

    context "with #created_at" do
      before { wsse.created_at = Time.now + 86400 }

      it "contains a wsu:Created node with the given time" do
        expect(wsse.to_xml).to include("<wsu:Created>#{wsse.created_at.utc.xmlschema}</wsu:Created>")
      end

      it "contains a wsu:Expires node set to #created_at + 60 seconds" do
        expect(wsse.to_xml).to include("<wsu:Expires>#{(wsse.created_at + 60).utc.xmlschema}</wsu:Expires>")
      end
    end

    context "with #expires_at" do
      before { wsse.expires_at = Time.now + 86400 }

      it "contains a wsu:Created node defaulting to Time.now" do
        created_at = Time.now
        Timecop.freeze created_at do
          expect(wsse.to_xml).to include("<wsu:Created>#{created_at.utc.xmlschema}</wsu:Created>")
        end
      end

      it "contains a wsu:Expires node set to the given time" do
        expect(wsse.to_xml).to include("<wsu:Expires>#{wsse.expires_at.utc.xmlschema}</wsu:Expires>")
      end
    end

    context "whith credentials and timestamp" do
      before do
        wsse.credentials "username", "password"
        wsse.timestamp = true
      end

      it "contains a wsu:Created node" do
        expect(wsse.to_xml).to include("<wsu:Created>")
      end

      it "contains a wsu:Expires node" do
        expect(wsse.to_xml).to include("<wsu:Expires>")
      end

      it "contains the username and password" do
        expect(wsse.to_xml).to include("username", "password")
      end
    end
  end

end
