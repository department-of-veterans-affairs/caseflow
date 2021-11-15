import React from 'react';
import { render } from '@testing-library/react';

import { axe } from 'jest-axe';

import { VsoVisibilityAlert } from 'app/queue/caseDetails/VsoVisibilityAlert';

describe('VsoVisibilityAlert', () => {
  const defaults = {};

  const setup = (props) =>
    render(<VsoVisibilityAlert {...defaults} {...props} />);

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
