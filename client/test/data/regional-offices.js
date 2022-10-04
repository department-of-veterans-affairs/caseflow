import { map } from 'lodash';
import regionalOfficesJsonResponse from './regionalOfficesJsonResponse';

export const regionalOfficeCities = {
  RO11: {
    city: 'Pittsburgh',
    state: 'PA',
    timezone: 'America/New_York'
  }
};

export const roList = map(
  regionalOfficesJsonResponse.regional_offices,
  (value, key) => ({ label: value.label, value: { key, ...value } })
);

export const roLocations = [
  {
    label: 'Holdrege, NE (VHA) 0 miles away',
    value: {
      name: 'Holdrege VA Clinic',
      address: '1118 Burlington Street, Holdrege NE 68949-1705',
      city: 'Holdrege',
      state: 'NE',
      zipCode: '68949-1705',
      distance: 0,
      classification: 'Primary Care CBOC',
      facilityId: 'vba_317a',
      facilityType: 'va_health_facility'
    }
  },
  {
    label: 'Holdrege, NE (VHA) 1 miles away',
    value: {
      name: 'Holdrege VA Clinic',
      address: '1118 Burlington Street, Holdrege NE 68949-1705',
      city: 'Holdrege',
      state: 'NE',
      zipCode: '68949-1705',
      distance: 1,
      classification: 'Primary Care CBOC',
      facilityId: 'vc_0742V',
      facilityType: 'va_health_facility'
    }
  },
  {
    label: 'Holdrege, NE (VHA) 2 miles away',
    value: {
      name: 'Holdrege VA Clinic',
      address: '1118 Burlington Street, Holdrege NE 68949-1705',
      city: 'Holdrege',
      state: 'NE',
      zipCode: '68949-1705',
      distance: 2,
      classification: 'Primary Care CBOC',
      facilityId: 'vba_317',
      facilityType: 'va_health_facility'
    }
  }
]
;
