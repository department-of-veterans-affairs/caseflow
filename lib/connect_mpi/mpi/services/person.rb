# frozen_string_literal: true

module MPI
  class PersonWebService < MPI::Base
    def self.service_name
      "people"
    end

    def method
      :prpa_in201305_uv02
    end

    def parametrize_gender(value)
      # value may be "F" or "M"
      Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <livingSubjectAdministrativeGender>
          <value code="#{value}" />
          <semanticsText>Gender</semanticsText>
        </livingSubjectAdministrativeGender>
      EOXML
    end

    def parametrize_date_of_birth(value)
      # value must be in "YYYYMMDD" format
      Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <livingSubjectBirthTime>
          <value value="#{value}" />
          <semanticsText>Date of Birth</semanticsText>
        </livingSubjectBirthTime>
      EOXML
    end

    def parametrize_ssn(value)
      # value must be \d{9}
      element = Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <livingSubjectId>
          <value root="2.16.840.1.113883.4.1" extension=""/>
          <semanticsText>SSN</semanticsText>
        </livingSubjectId>
      EOXML
      element.at_xpath(".//*[name()='value']")["extension"] = value
      element
    end

    def parametrize_name(last_name:, first_name: nil, middle_name: nil)
      element = Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <livingSubjectName>
          <value use="L"></value>
          <semanticsText>Legal Name</semanticsText>
        </livingSubjectName>
      EOXML
      value = element.at_xpath(".//*[name()='value']")
      if first_name.present?
        node = Nokogiri::XML::DocumentFragment.parse("<given/>")
        node.children[0].content = first_name
        value.add_child(node)
        if middle_name.present?
          node = Nokogiri::XML::DocumentFragment.parse("<given/>")  # second <given> is middle name
          node.children[0].content = middle_name
          value.add_child(node)
        end
      end
      if last_name.present?
        node = Nokogiri::XML::DocumentFragment.parse("<family/>")
        node.children[0].content = last_name
        value.add_child(node)
      end
      element
    end

    def parametrize_mothers_maiden_name(value)
      element = Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <livingSubjectName>
          <value use="C">
            <family/>
          </value>
          <semanticsText>Mother's Maiden Name</semanticsText>
        </livingSubjectName>
      EOXML
      element.at_xpath(".//*[name()='family']").content = value
      element
    end

    def parametrize_address(address)
      element = Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <patientAddress>
          <value use="PHYS"/>
          <semanticsText>Physical Address</semanticsText>
        </patientAddress>
      EOXML
      value = element.at_xpath(".//*[name()='value']")
      {
        street: "streetAddressLine",
        city: "city",
        state: "state",
        postal_code: "postalCode",
        country: "country"
      }.each do |key, name|
        if address[key].present?
          fragment = Nokogiri::XML::DocumentFragment.parse("<#{name}/>")
          fragment.children[0].content = address[key]
          value.add_child(fragment)
        end
      end
      element
    end

    def parametrize_telephone(value)
      value = value[1..] if value[0] == "1" && value.length == 11
      value = "+1-#{value[0..2]}-#{value[3..5]}-#{value[6..9]}" if value.length == 10
      element = Nokogiri::XML::DocumentFragment.parse <<-EOXML
        <patientTelecom>
          <value/>
          <semanticsText>Home Phone</semanticsText>
        </patientTelecom>
      EOXML
      element.at_xpath(".//*[name()='value']")["value"] = "tel:#{value}"
      element
    end

    def search_people_info(last_name:, first_name: nil, middle_name: nil,
                           ssn: nil, date_of_birth: nil, gender: nil, address: nil, telephone: nil)
      query = Nokogiri::XML::DocumentFragment.parse <<-EOXML
  <queryByParameter>
      <!-- Unique identifier for the query  -->
      <queryId extension="18204" root="1.2.840.114350.1.13.28.1.18.5.999"/>
      <!-- The status of the query, default is "new" -->
      <statusCode code="new"/>
      <!-- MVI.COMP1=Add GetCorIds only Correlations MVI.COMP2=Add GetCorIds with Correlations and ICN History -->
      <modifyCode code="MVI.COMP1"/>
      <!-- Attribute 'responseElementGroupId' indicates if Response should be the Primary View or Correlation, default is Primary View. -->
      <!-- extension="PV" root="2.16.840.1.113883.4.349  = Return Primary View -->
      <!-- extension="COR" root="2.16.840.1.113883.4.349 = Return Correlation -->
      <responseElementGroupId extension="PV" root="2.16.840.1.113883.4.349"/>
      <!-- The return quantity should always be 1 for the retrieve -->
      <!-- For Attended Searches initialQuantity should always GREATER than '1' -->
      <initialQuantity value="10" />
      <parameterList>
      </parameterList>
  </queryByParameter>
EOXML
      params = query.at_xpath(".//*[name()='parameterList']")
      params.add_child(parametrize_name(last_name: last_name, first_name: first_name, middle_name: middle_name))
      params.add_child(parametrize_ssn(ssn)) if ssn.present?
      params.add_child(parametrize_date_of_birth(date_of_birth)) if date_of_birth.present?
      params.add_child(parametrize_gender(gender)) if gender.present?
      params.add_child(parametrize_address(address)) if address.present?
      params.add_child(parametrize_telephone(telephone)) if telephone.present?

      response = request(method, build_request_xml(method, query))

      cap = response[:prpa_in201306_uv02][:control_act_process]
      response_code = cap[:query_ack][:query_response_code][:@code]
      raise NotFoundError if response_code == "NF"
      raise QueryResultError if response_code == "QE"
      raise ApplicationError if response_code == "AE"

      [cap[:subject]].flatten
    end
  end
end
