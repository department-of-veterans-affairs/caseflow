import React from 'react';
import { axe } from 'jest-axe';
import { Provider } from 'react-redux';
import userEvent from '@testing-library/user-event';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import selectEvent from 'react-select-event';
import { MemoryRouter as Router } from 'react-router-dom';

import ReportPage from 'app/nonComp/pages/ReportPage';
import { getVhaUsers } from 'test/helpers/reportPageHelper';
import createNonCompStore from './nonCompStoreCreator';

const setup = (storeValues = { nonComp: { businessLineUrl: 'vha' } }) => {
  const store = createNonCompStore(storeValues);

  return render(
    <Provider store={store}>
      <Router>
        <ReportPage />
      </Router>
    </Provider>
  );
};

const navigateToPersonnel = async () => {
  await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event / Action']);

  const addConditionBtn = screen.getByText('Add Condition');

  userEvent.click(addConditionBtn);

  const selectText = screen.getByText('Select a variable');

  await selectEvent.select(selectText, ['Personnel']);
};

beforeEach(() => {
  getVhaUsers();
});

describe('Personnel', () => {
  describe('component renders correctly', () => {
    it('passes a11y testing', async () => {
      const { container } = setup();

      await navigateToPersonnel();

      const results = await axe(container);

      expect(results).toHaveNoViolations();
    });

    it('renders correctly', async () => {
      const { container } = setup();

      await navigateToPersonnel();

      expect(container).toMatchSnapshot();
    });
  });

  describe('component functions correctly', () => {
    beforeEach(async () => {
      setup();
      await navigateToPersonnel();
    });

    const selectPlaceholder = 'Select...';
    const teamMember1 = 'VHAUSER01';

    it('renders a dropdown with the correct label', async () => {
      expect(screen.getByText('VHA team members')).toBeInTheDocument();
      expect(screen.getAllByText(selectPlaceholder).length).toBe(2);
    });

    it('allows to select multiple options from dropdown', async () => {
      let selectText = screen.getAllByText(selectPlaceholder);

      await selectEvent.select(selectText[1], [teamMember1]);

      selectText = screen.getByText(teamMember1);
      const teamMember2 = 'VHAUSER02';

      await selectEvent.select(selectText, [teamMember2]);

      expect(screen.getByText(teamMember1)).toBeInTheDocument();
      expect(screen.getByText(teamMember2)).toBeInTheDocument();
    });

    it('selects an option from dropdown, then removes it and renders an error', async () => {
      const selectText = screen.getAllByText(selectPlaceholder);

      await selectEvent.select(selectText[1], [teamMember1]);
      expect(screen.getByText(teamMember1)).toBeInTheDocument();

      const clearBtn = document.querySelector('.cf-select__indicator.cf-select__clear-indicator');

      userEvent.click(clearBtn);

      expect(screen.queryByText(teamMember1)).not.toBeInTheDocument();

      const generateTaskReport = screen.getByRole('button', { name: 'Generate task report' });

      expect(generateTaskReport).not.toHaveClass('usa-button-disabled');

      // Wait for the validation text to appear before making assertions
      await fireEvent.click(generateTaskReport);
      await waitFor(() => {
        const validationText = screen.getByText('Please select at least one team member');

        expect(validationText).toBeInTheDocument();
      });
    });
  });
});
