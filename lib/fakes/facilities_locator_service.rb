class Fakes::FacilitiesLocatorService

  def self.get_closest(point, ids)

    {
      data: [
        {
          id: "vha_688",
          type: "va_facilities",
          attributes: {
            name: "Washington VA Medical Center",
            facility_type: "va_health_facility",
            classification: "VA Medical Center (VAMC)",
            lat: 38.9311137,
            long: -77.0109110499999,
            website: "http://www.washingtondc.va.gov",
            address: {
              mailing: {
                address_1: "50 Irving Street, Northwest",
                address_2: "string",
                address_3: "string",
                city: "Washington",
                state: "DC",
                zip: "20422-0001"
              },
              physical: {
                address_1: "50 Irving Street, Northwest",
                address_2: "string",
                address_3: "string",
                city: "Washington",
                state: "DC",
                zip: "20422-0001"
              }
            },
            phone: {
              main: "202-555-1212",
              fax: "202-555-1212",
              pharmacy: "202-555-1212",
              after_hours: "202-555-1212",
              patient_advocate: "202-555-1212",
              mental_health_clinic: "202-555-1212",
              enrollment_coordinator: "202-555-1212"
            },
            hours: {
              "Monday": "9AM-5PM",
              "Tuesday": "9AM-5PM",
              "Wednesday": "9AM-5PM",
              "Thursday": "9AM-5PM",
              "Friday": "9AM-5PM",
              "Saturday": "Closed",
              "Sunday": "Closed"
            },
            services: {
              other: [
                "Online Scheduling"
              ],
              health: [
                "PrimaryCare"
              ],
              benefits: [
                "ApplyingForBenefits"
              ],
              last_updated: "2018-01-01"
            },
            satisfaction: {
              health: {
                primary_care_urgent: 0.85,
                primary_care_routine: 0.85,
                specialty_care_urgent: 0.85,
                specialty_care_routine: 0.85
              },
              effective_date: "2018-01-01"
            },
            wait_times: {
              health: [
                {
                  service: "PrimaryCare",
                  new: 10,
                  established: 5
                }
              ],
              effective_date: "2018-01-01"
            }
          }
        }
      ]
    }

  end
end
