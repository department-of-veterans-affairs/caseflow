# frozen_string_literal: true

# rubocop:disable Layout/LineLength
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ParameterLists
# rubocop:disable Style/WordArray
class Fakes::MPIService
  # :reek:LongParameterList
  # :reek:UnusedParameters
  def search_people_info(last_name:, first_name: nil, middle_name: nil,
                         ssn: nil, date_of_birth: nil, gender: nil, address: nil, telephone: nil)
    name = "#{first_name} #{last_name}"
    fail MPI::NotFoundError if name == "Not Found"
    fail MPI::QueryResultError if name == "Too Vague"
    fail MPI::ApplicationError if name == "Database Down"
    fail Savon::SOAPFault.new(nil, Nori.new, '<?xml version="1.0" ?><env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"><env:Body><env:Fault><faultcode>env:Client</faultcode><faultstring>Internal Error</faultstring></env:Fault></env:Body></env:Envelope>') if name == "System Unreachable"

    [
      {
        registration_event: {
          id: { :@null_flavor => "NA" },
          status_code: { :@code => "active" },
          subject1: {
            patient: {
              id: [
                { :@extension => "1200028056V759470^NI^200M^USVHA^P", :@root => "2.16.840.1.113883.4.349" },
                { :@extension => "6005638^PN^200EDR^USDVA^A", :@root => "2.16.840.1.113883.4.349" }
              ],
              status_code: { :@code => "active" },
              patient_person: {
                name: { given: ["MADISON", "I"], family: "WESTBROOK", :@use => "L" },
                administrative_gender_code: { :@code => "F" },
                birth_time: { :@value => "19930126" },
                as_other_i_ds: [
                  {
                    id: { :@extension => "627014691", :@root => "2.16.840.1.113883.4.1" },
                    status_code: { :@code => "4" },
                    scoping_organization: {
                      id: { :@root => "1.2.840.114350.1.13.99997.2.3412" },
                      :@class_code => "ORG",
                      :@determiner_code => "INSTANCE"
                    },
                    :@class_code => "SSN"
                  },
                  {
                    id: { :@extension => "6005638^PN^200EDR^USDVA^A", :@root => "2.16.840.1.113883.4.349" },
                    scoping_organization: {
                      id: { :@root => "2.16.840.1.113883.4.349" },
                      :@class_code => "ORG",
                      :@determiner_code => "INSTANCE"
                    },
                    :@class_code => "PAT"
                  }
                ],
                birth_place: {
                  addr: { city: "BOISE", state: "ID", country: "USA" }
                }
              },
              subject_of1: {
                query_match_observation: {
                  code: { :@code => "IHE_PDQ" },
                  value: { :"@xsi:type" => "INT", :@value => "100" },
                  :@class_code => "COND",
                  :@mood_code => "EVN"
                }
              },
              :@class_code => "PAT"
            },
            :@type_code => "SBJ"
          },
          custodian: {
            assigned_entity: {
              id: { :@root => "2.16.840.1.113883.4.349" },
              :@class_code => "ASSIGNED"
            },
            :@type_code => "CST"
          },
          :@class_code => "REG",
          :@mood_code => "EVN"
        },
        :@type_code => "SUBJ"
      },
      { :registration_event =>
        { :id => { :@null_flavor => "NA" },
          :status_code => { :@code => "active" },
          :subject1 =>
          { :patient =>
            { :id =>
              [{ :@extension => "1200028054V494652^NI^200M^USVHA^P", :@root => "2.16.840.1.113883.4.349" },
               { :@extension => "6005636^PN^200EDR^USDVA^A", :@root => "2.16.840.1.113883.4.349" }],
              :status_code => { :@code => "active" },
              :patient_person =>
              { name: { :given => ["MADISON", "G"], :family => "WESTBROOK", :@use => "L" },
                administrative_gender_code: { :@code => "F" },
                birth_time: { :@value => "19930125" },
                as_other_i_ds:
                [{ :id => { :@extension => "627014689", :@root => "2.16.840.1.113883.4.1" },
                   :status_code => { :@code => "4" },
                   :scoping_organization =>
                   { :id => { :@root => "1.2.840.114350.1.13.99997.2.3412" },
                     :@class_code => "ORG",
                     :@determiner_code => "INSTANCE" },
                   :@class_code => "SSN" },
                 { :id => { :@extension => "6005636^PN^200EDR^USDVA^A", :@root => "2.16.840.1.113883.4.349" },
                   :scoping_organization =>
                   { :id => { :@root => "2.16.840.1.113883.4.349" },
                     :@class_code => "ORG",
                     :@determiner_code => "INSTANCE" },
                   :@class_code => "PAT" }],
                birth_place: { addr: { city: "MARIETTA", state: "GA", country: "USA" } } },
              :subject_of1 =>
              { query_match_observation:
                { :code => { :@code => "IHE_PDQ" },
                  :value => { :"@xsi:type" => "INT", :@value => "135" },
                  :@class_code => "COND",
                  :@mood_code => "EVN" } },
              :subject_of2 =>
              { :administrative_observation =>
                { :code =>
                  { :@code => "PERSON_TYPE",
                    :@code_system => "2.16.840.1.113883.4.349",
                    :@display_name => "Person Type" },
                  :value =>
                  { :@code => "EMP~HPT~VET",
                    :"@xsi:type" => "CD",
                    :@display_name => "Employee, Unknown, Veteran" },
                  :@class_code => "VERIF" },
                :@type_code => "SBJ" },
              :@class_code => "PAT" },
            :@type_code => "SBJ" },
          :custodian =>
          { :assigned_entity => { :id => { :@root => "2.16.840.1.113883.4.349" }, :@class_code => "ASSIGNED" },
            :@type_code => "CST" },
          :@class_code => "REG",
          :@mood_code => "EVN" },
        :@type_code => "SUBJ" }
    ]
  end
end

# rubocop:enable Style/WordArray
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Metrics/MethodLength
# rubocop:enable Layout/LineLength
