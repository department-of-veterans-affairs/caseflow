import React from 'react';
import { render } from '@testing-library/react';
import { axe } from 'jest-axe';

// import COPY from 'app/../COPY';

import { AddClaimantPage } from 'app/intake/addClaimant/AddClaimantPage';
import { IntakeProviders } from '../../testUtils';

describe('AddClaimantPage', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = () => {
    return render(<AddClaimantPage />, { wrapper: IntakeProviders });
  };

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  describe('Claimant Type Fields', () => {

    describe('Individual Name Fields', () => {
      it("isn't rendered when no claimant type has been selected", () => {
        setup();

        const individualForm = screen.queryByLabelText('individualForm');

        expect(individualForm).not.toBeInTheDocument();
      });
    });
  });
});
