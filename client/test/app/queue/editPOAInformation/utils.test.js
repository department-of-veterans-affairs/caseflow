import { mapPOADataToApi, mapPOADataFromApi } from 'app/queue/editPOAInformation/utils';

describe('api utils', () => {
  describe('mapPOADataToApi', () => {
    describe('listed attorney', () => {
      it('should only send poa_participant_id to api', () => {
        const listedPOA = {
          listedAttorney: {
            address: {
              address_line_1: 'addressLine1',
              address_line_2: 'addressLine2',
              address_line_3: 'addressLine3',
              city: 'city',
              country: 'country',
              state: 'state',
              zip: 'zip'
            },
            label: 'label',
            value: 'value'
          }
        };
        const mappedData = mapPOADataToApi(listedPOA);

        expect(mappedData).toEqual({
          unrecognized_appellant: {
            poa_participant_id: 'value'
          }
        });
      });
    });

    describe('unlisted attorney', () => {
      it('should map poa data to api w/ null poa_participant_id', () => {
        const unlistedPOA = {
          addressLine1: 'addressLine1',
          addressLine2: 'addressLine2',
          addressLine3: 'addressLine3',
          city: 'city',
          country: 'country',
          state: 'state',
          zip: 'zip',
          firstName: 'name',
          partyType: 'type',
          listedAttorney: {
            label: 'Name not listed',
            value: 'not_listed'
          },
        };
        const mappedData = mapPOADataToApi(unlistedPOA);

        expect(mappedData).toEqual({
          unrecognized_appellant: {
            poa_participant_id: null,
            unrecognized_power_of_attorney: {
              address_line_1: 'addressLine1',
              address_line_2: 'addressLine2',
              address_line_3: 'addressLine3',
              city: 'city',
              country: 'country',
              name: 'name',
              party_type: 'type',
              state: 'state',
              zip: 'zip'
            }
          }
        });
      });
    });
  });

  describe('mapPOADataFromApi', () => {
    it('should map data from api to expected object even if not all fields present', () => {
      const appeal = {
        hasPOA: true,
        powerOfAttorney: {
          representative_address: {
            address_line_1: 'addressLine1',
            address_line_2: 'addressLine2',
            address_line_3: 'addressLine3',
            city: 'city',
            country: 'country',
            state: 'state',
            zip: 'zip',
          },
          representative_name: 'name',
          representative_type: 'type',
          representative_tz: 'zone'
        }
      };

      const mappedData = mapPOADataFromApi(appeal);

      expect(mappedData).toEqual({
        addressLine1: 'addressLine1',
        addressLine2: 'addressLine2',
        addressLine3: 'addressLine3',
        city: 'city',
        country: 'country',
        emailAddress: undefined,
        name: 'name',
        relationship: 'attorney',
        state: 'state',
        type: 'type',
        zip: 'zip',
        zone: 'zone'
      });
    });
  });
});
