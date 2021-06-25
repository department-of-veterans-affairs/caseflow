import React from 'react';
import { axe } from 'jest-axe';
import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router';

import { AppealHasSubstitutionAlert } from 'app/queue/substituteAppellant/caseDetails/AppealHasSubstitutionAlert';

describe('AppealHasSubstitutionAlert', () => {
  const defaults = {
    targetAppealId: 'abc123',
  };

  const setup = (props) =>
    render(
      <MemoryRouter>
        <AppealHasSubstitutionAlert {...defaults} {...props} />
      </MemoryRouter>
    );

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
