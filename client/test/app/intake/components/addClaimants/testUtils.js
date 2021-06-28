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

const organization = 'Tista';
const street1 = '1000 Monticello';
const city = 'Washington';
const zip = '20000';
const country = 'USA';

export const fillForm = async () => {
  //   Enter organization
  await userEvent.type(
    screen.getByRole('textbox', { name: /Organization name/i }),
    organization
  );

  //   Enter  Street1
  await userEvent.type(
    screen.getByRole('textbox', { name: /Street address 1/i }),
    street1
  );

  //   Enter city
  await userEvent.type(screen.getByRole('textbox', { name: /City/i }), city);

  // select state
  await selectEvent.select(screen.getByLabelText('State'), [STATES[7].label]);

  // Enter zip
  await userEvent.type(screen.getByRole('textbox', { name: /Zip/i }), zip);
  // Enter country
  await userEvent.type(
    screen.getByRole('textbox', { name: /Country/i }),
    country
  );

  await userEvent.click(screen.getByRole('radio', { name: /no/i }));
};
