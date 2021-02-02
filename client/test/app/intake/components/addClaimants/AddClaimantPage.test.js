import React from 'react';
import { screen, render } from '@testing-library/react';
import { axe } from 'jest-axe';

import COPY from 'app/../COPY';

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
});
