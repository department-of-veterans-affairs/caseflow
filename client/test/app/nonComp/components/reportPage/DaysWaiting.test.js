import React from 'react';
import { axe } from 'jest-axe';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';

import userEvent from '@testing-library/user-event';
import { render, screen } from '@testing-library/react';
import ReportPage from 'app/nonComp/pages/ReportPage';
import selectEvent from 'react-select-event';
import { getVhaUsers } from 'test/helpers/reportPageHelper';
import createNonCompStore from '../../nonCompStoreCreator';

describe('DaysWaiting', () => {
  const setup = (storeValues = {}) => {
    const store = createNonCompStore(storeValues);

    return render(
      <Provider store={store}>
        <Router>
          <ReportPage />
        </Router>
      </Provider>
    );
  };

  const navigateToDaysWaiting = async () => {
    await selectEvent.select(screen.getByLabelText('Report Type'), ['Event / Action']);
    const addConditionButton = screen.getByText('Add Condition');

    await userEvent.click(addConditionButton);
    const select = screen.getByText('Select a variable');

    await selectEvent.select(select, ['Days Waiting']);
  };

  beforeEach(() => {
    getVhaUsers();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    await navigateToDaysWaiting();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', async () => {
    const { container } = setup();

    await navigateToDaysWaiting();

    expect(container).toMatchSnapshot();
  });

  it('shows two number fields for between', async () => {
    setup();
    await navigateToDaysWaiting();

    const otherSelect = screen.getByLabelText('Time Range');

    await selectEvent.select(otherSelect, ['Between']);

    const fieldOne = screen.getByText('Min days');
    const fieldTwo = screen.getByText('Max days');

    expect(fieldOne).toBeInTheDocument();
    expect(fieldTwo).toBeInTheDocument();
  });

  it('shows one number field for other options', async () => {
    setup();
    await navigateToDaysWaiting();

    const select = screen.getByLabelText('Time Range');

    await selectEvent.select(select, ['Equal to']);

    const fieldOne = screen.getByText('Number of days');
    const fieldTwo = screen.queryByText('Max days');

    expect(fieldOne).toBeInTheDocument();
    expect(fieldTwo).not.toBeInTheDocument();
  });
});
