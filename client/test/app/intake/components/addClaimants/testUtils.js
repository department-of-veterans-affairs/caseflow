import { screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';

import { STATES } from 'app/constants/AppConstants';

export const relationshipOpts = [
  { value: 'attorney', label: 'Attorney (previously or currently)' },
  { value: 'child', label: 'Child' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'other', label: 'Other' },
];

export const relationshipOptsHlrSc = [
  { value: 'attorney', label: 'Attorney (previously or currently)' },
  { value: 'child', label: 'Child' },
  { value: 'spouse', label: 'Spouse' },
  { value: 'healthcare_provider', label: 'Healthcare Provider' },
  { value: 'other', label: 'Other' },
];

const organization = 'Tista';
const street1 = '1000 Monticello';
const city = 'Washington';
const zip = '20000';
const country = 'USA';
const ein = '123456789'

export const fillForm = async (isHLROrSCForm = false) => {
  //   Enter organization
  await userEvent.type(
    screen.getByRole('textbox', { name: /Organization name/i }),
    organization
  );

  if (isHLROrSCForm) {
    await userEvent.type(
      screen.getByRole('textbox', { name: /employer identification number/i }),
      ein
    );
  }
  //   Enter  Street1
  await userEvent.type(
    screen.getByRole('textbox', { name: /Street address 1/i }),
    street1
  );

  //   Enter city
  await userEvent.type(screen.getByRole('textbox', { name: /City/i }), city);

  // select state
  await selectEvent.select(screen.getByRole('combobox', { name: /state/i }), [STATES[7].label]);

  // Enter zip
  await userEvent.type(screen.getByRole('textbox', { name: /Zip/i }), zip);
  // Enter country
  await userEvent.type(
    screen.getByRole('textbox', { name: /Country/i }),
    country
  );

  await userEvent.click(screen.getByRole('radio', { name: /no/i }));
};
