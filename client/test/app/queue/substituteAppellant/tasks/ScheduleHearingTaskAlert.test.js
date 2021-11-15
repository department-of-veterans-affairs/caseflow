import React from 'react';
import { render } from '@testing-library/react';

import { axe } from 'jest-axe';

import { ScheduleHearingTaskAlert } from 'app/queue/substituteAppellant/tasks/ScheduleHearingTaskAlert';

describe('ScheduleHearingTaskAlert', () => {
  const defaults = {};

  const setup = (props) =>
    render(<ScheduleHearingTaskAlert {...defaults} {...props} />);

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
