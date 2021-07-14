import { lowerCase } from 'lodash';

// Used to map form data from the form to the shape expected by the API
export const mapAppellantDataToApi = (appellant) => {
  // CASEFLOW-1923: Map the incoming data to match the shape expected by the API
  return appellant;
}

// Used to map the existing data from the API to the shape expected by the form
export const mapAppellantDataFromApi = (appeal) => {
  return {
    relationship: lowerCase(appeal.appellantRelationship),
    partyType: appeal.appellantPartyType,
    name: appeal.appellantFullName,
    firstName: appeal.appellantFirstName,
    middleName: appeal.appellantMiddleName,
    lastName: appeal.appellantLastName,
    suffix: appeal.appellantSuffix,
    addressLine1: appeal.appellantAddress.address_line_1,
    addressLine2: appeal.appellantAddress.address_line_2,
    addressLine3: appeal.appellantAddress.address_line_3,
    city: appeal.appellantAddress.city,
    state: appeal.appellantAddress.state,
    zip: appeal.appellantAddress.zip,
    country: appeal.appellantAddress.country,
    phoneNumber: appeal.appellantPhoneNumber,
    emailAddress: appeal.appellantEmailAddress,
    poaForm: (appeal.appellantUnrecognizedPOAId !== null).toString()
  };
};