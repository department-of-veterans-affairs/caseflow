import React from 'react';
import { screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { createMemoryHistory } from 'history';

import { AddPoaPage } from 'app/intake/addPOA/AddPoaPage';
import { renderIntakePage } from '../testUtils';
import { generateInitialState } from 'app/intake/index';
import { PAGE_PATHS } from 'app/intake/constants';

describe('AddPoaPage', () => {
  const onSubmit = jest.fn();
  const onBack = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
  });
  const defaults = { onSubmit, onBack };
  const setup = (
    storeValues,
    history = createMemoryHistory({ initialEntries: [PAGE_PATHS.ADD_POWER_OF_ATTORNEY] }),
  ) => {
    const page = <AddPoaPage {...defaults} />;

    return renderIntakePage(page, storeValues, history);
  };

  it('renders default state correctly', async () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
    await waitFor(() => {
      expect(
        screen.getByText("Add Claimant's POA")
      ).toBeInTheDocument();
    });
  });

  it('fires onBack', async () => {
    setup();

    const backButton = screen.getByRole('button', { name: /back/i });

    expect(onBack).not.toHaveBeenCalled();

    await waitFor(() => {
      userEvent.click(backButton);
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

      expect(await history.location.pathname).toBe(PAGE_PATHS.ADD_POWER_OF_ATTORNEY);
    });
  });
});
