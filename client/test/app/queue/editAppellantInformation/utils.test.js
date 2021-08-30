import { mapAppellantDataFromApi } from 'app/queue/editAppellantInformation/utils';

describe('mapAppellantDataFromApi', () => {

  it('should map data from api to expected object even if not all fields present', () => {
    const appeal = {
      'appellantRelationship': 'Child',
      'appellantPartyType': 'Individual',
      'appellantFirstName': 'first',
      'appellantLastName': 'last',
      'appellantDateOfBirth': '01/01/2000',
      'appellantAddress': {
        'address_line_1': 'addressLine1',
        'address_line_2': 'addressLine2',
        'address_line_3': 'addressLine3',
        'city': 'city',
        'state': 'state',
        'zip': 'zip',
        'country': 'country'
      }
    };

    const mappedData = mapAppellantDataFromApi(appeal);

    expect(mappedData).toEqual({
      'addressLine1': 'addressLine1',
      'addressLine2': 'addressLine2',
      'addressLine3': 'addressLine3',
      'city': 'city',
      'country': 'country',
      'dateOfBirth': '01/01/2000',
      'emailAddress': undefined,
      'firstName': 'first',
      'lastName': 'last',
      'middleName': undefined,
      'name': undefined,
      'partyType': 'Individual',
      'phoneNumber': undefined,
      'relationship': 'child',
      'state': 'state',
      'suffix': undefined,
      'zip': 'zip',
      'listedAttorney': {
        'value': 'not_listed'
      },
    });
  });
});
