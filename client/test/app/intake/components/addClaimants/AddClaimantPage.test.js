import React from 'react';
import { screen, waitFor } from '@testing-library/react';
import { axe } from 'jest-axe';
import userEvent from '@testing-library/user-event';
import selectEvent from 'react-select-event';
import { createMemoryHistory } from 'history';

import { AddClaimantPage } from 'app/intake/addClaimant/AddClaimantPage';
import { renderIntakePage } from '../../testUtils';
import { generateInitialState } from 'app/intake/index';
import { PAGE_PATHS } from 'app/intake/constants';
import { fillForm, relationshipOpts } from './testUtils';

describe('AddClaimantPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onSubmit, onBack };
  const setup = (
    storeValues,
    history = createMemoryHistory({ initialEntries: [PAGE_PATHS.ADD_CLAIMANT] }),
  ) => {
    const page = <AddClaimantPage {...defaults} />;

    return renderIntakePage(page, storeValues, history);
  };

  it('renders default state correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    expect(screen.getByText('Add Claimant')).toBeInTheDocument();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('fires onBack', async () => {
    setup();

    const backButton = screen.getByRole('button', { name: /back/i });

    expect(onBack).not.toHaveBeenCalled();

    await userEvent.click(backButton);
    await waitFor(() => {
      expect(onBack).not.toHaveBeenCalled();
    });
  });

  describe('Redirection to Intake home page', () => {
    let storeValues;

    beforeEach(() => {
      storeValues = generateInitialState();
    });

    it('takes place whenever intake has been cancelled (formType === null)', async () => {
      storeValues.intake = {
        ...storeValues.intake,
        formType: null
      };

      const { history } = setup(storeValues);

      expect(await history.location.pathname).toBe(PAGE_PATHS.BEGIN);
    });

    it('does not take place is there is a formType, indicating no cancellation', async () => {
      storeValues.intake = {
        ...storeValues.intake,
        formType: 'appeal'
      };

      const { history } = setup(storeValues);

      expect(await history.location.pathname).toBe(PAGE_PATHS.ADD_CLAIMANT);
    });
  });
});
