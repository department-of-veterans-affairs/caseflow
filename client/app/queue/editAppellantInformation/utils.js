import { lowerCase } from 'lodash';

// Used to map form data from the form to the shape expected by the API
export const mapAppellantDataToApi = (appellant) => {
  return { unrecognized_appellant: {
      relationship: appellant.relationship,
      unrecognized_party_detail: {
        party_type: (appellant.relationship === "other" || appellant.relationship === "attorney") ? appellant.partyType : "individual",
        name: appellant.partyType === "organization" ? appellant.name : appellant.firstName,
        middle_name: appellant.middleName || "",
        last_name: appellant.lastName || "",
        suffix: appellant.suffix,
        address_line_1: appellant.addressLine1,
        address_line_2: appellant.addressLine2,
        address_line_3: appellant.addressLine3,
        city: appellant.city,
        state: appellant.state,
        zip: appellant.zip,
        country: appellant.country,
        phone_number: appellant.phoneNumber,
        email_address: appellant.emailAddress
      }
    }
  };
}

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
    listedAttorney: {
      value: 'not_listed'
    }
  };
};

export const mapPOADataFromApi = (appeal) => {
  console.log(appeal);
  return {
    relationship: 'attorney'
  }
}