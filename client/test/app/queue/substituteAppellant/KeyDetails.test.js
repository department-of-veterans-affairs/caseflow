import React from 'react';
import { render } from '@testing-library/react';

import { axe } from 'jest-axe';
import { sub } from 'date-fns';

import { KeyDetails } from 'app/queue/substituteAppellant/tasks/KeyDetails';

describe('KeyDetails', () => {
  const defaults = {
    nodDate: sub(new Date(), { days: 30 }),
    dateOfDeath: sub(new Date(), { days: 15 }),
    substitutionDate: sub(new Date(), { days: 10 }),
  };

  const setup = (props) => render(<KeyDetails {...defaults} {...props} />);

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
