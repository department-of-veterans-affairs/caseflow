import React from 'react';
import { render } from '@testing-library/react';

import { axe } from 'jest-axe';
import { sub } from 'date-fns';

import { KeyDetails } from 'app/queue/substituteAppellant/tasks/KeyDetails';
import { MemoryRouter } from 'react-router';

describe('KeyDetails', () => {
  const defaults = {
    appealId: 'abc123',
    nodDate: sub(new Date(), { days: 30 }),
    dateOfDeath: sub(new Date(), { days: 15 }),
    substitutionDate: sub(new Date(), { days: 10 }),
  };

  const setup = (props) =>
    render(
      <MemoryRouter>
        <KeyDetails {...defaults} {...props} />
      </MemoryRouter>
    );

  it('renders default state correctly', () => {
    // Choose a date so snapshot doesn't depend on todays date
    const aprilThirty = new Date('2021-04-30');
    const { container } = setup({
      nodDate: sub(aprilThirty, { days: 30 }),
      dateOfDeath: sub(aprilThirty, { days: 15 }),
      substitutionDate: sub(aprilThirty, { days: 10 })
    });

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
