import React from 'react';
import { axe } from 'jest-axe';

import userEvent from '@testing-library/user-event';
import { fireEvent, render, screen } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import ReportPage from 'app/nonComp/pages/ReportPage';
import selectEvent from 'react-select-event';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { shallow } from 'enzyme';

describe('ReportPage', () => {
  const setup = () => {
    return render(
      <ReportPage />
    );
  };

  const clickOnReportType = async () => {
    setup();
    await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event / Action']);
  };

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('brings you to the decision review page when clicking the cancel button', async () => {
    const history = createMemoryHistory();

    render(
      <ReportPage history={history} />
    );

    const cancelButton = screen.getByText('Cancel');

    await userEvent.click(cancelButton);

    expect(history.location.pathname).toBe('/vha');
  });

  describe('conditions section', () => {
    beforeEach(clickOnReportType);

    it('adds a condition variable when you click add condition', async () => {

      const addConditionButton = screen.getByText('Add Condition');

      await userEvent.click(addConditionButton);

      expect(screen.getByText('Select a variable')).toBeInTheDocument();
      expect(screen.getByText('Remove condition')).toBeInTheDocument();
    });

    it('removes condition variables when clicking the remove condition link', async () => {
      const addConditionButton = screen.getByText('Add Condition');

      await userEvent.click(addConditionButton);

      const selectText = screen.getByText('Select a variable');
      const removeConditionLink = screen.getByText('Remove condition');

      await userEvent.click(removeConditionLink);

      expect(selectText).not.toBeInTheDocument();
      expect(removeConditionLink).not.toBeInTheDocument();
    });

    it('only allows up to 5 variables before disabling the add condition button', async () => {
      const addConditionButton = screen.getByText('Add Condition');

      for (let count = 0; count < 5; count++) {
        await userEvent.click(addConditionButton);
      }

      expect(addConditionButton).toBeDisabled();
    });

    it('disables the dropdown once an option is chosen', async () => {
      const addConditionButton = screen.getByText('Add Condition');

      await userEvent.click(addConditionButton);

      const select = screen.getByText('Select a variable');

      await selectEvent.select(select, ['Days Waiting']);

      // try to open the same dropdown again
      await selectEvent.openMenu(select);
      expect(screen.queryByText('Facility')).not.toBeInTheDocument();
    });

    it('does not allow repeat variables', async () => {
      const addConditionButton = screen.getByText('Add Condition');

      for (let count = 0; count < 2; count++) {
        await userEvent.click(addConditionButton);
      }

      // Select Days waiting, then open another dropdown and it shouldn't be in that dropdown
      const selects = screen.getAllByText('Select a variable');

      await selectEvent.select(
        selects[0],
        ['Days Waiting']
      );

      await selectEvent.openMenu(selects[1]);
      expect(screen.getAllByText('Days Waiting').length).toBe(1);
    });

    it('does not allow personnel and facility to be selected at the same time', async () => {
      const addConditionButton = screen.getByText('Add Condition');

      for (let count = 0; count < 2; count++) {
        await userEvent.click(addConditionButton);
      }

      const selects = screen.getAllByText('Select a variable');

      await selectEvent.select(
        selects[0],
        ['Personnel']
      );

      await selectEvent.openMenu(selects[1]);
      expect(screen.queryByText('Facility')).not.toBeInTheDocument();
    });
  });

  it('should have Generate task Report button and Clear Filter button disabled on initial load', () => {
    render(
      <ReportPage />
    );

    const generateTaskReport = screen.getByRole('button', { name: /Generate task Report/i });

    expect(generateTaskReport).toHaveClass('usa-button-disabled');

    const clearFilters = screen.getByText('Clear filters');

    expect(clearFilters).toHaveClass('usa-button-disabled');
  });

  describe('Timing Specification Section', () => {
    beforeEach(clickOnReportType);

    it('should have Timing Specifications as header', () => {
      const h2 = screen.getByText(/Timing specifications/);

      expect(h2).toBeInTheDocument();
    });

    it('should have a dropdown name Range', () => {
      const dropdownName = screen.getByText(/Range/);

      expect(dropdownName).toBeInTheDocument();
    });

    it('adds a datetime field with name Date when you select After option', async () => {
      await selectEvent.select(screen.getByLabelText('Range'), ['After']);

      expect(screen.getAllByText('After').length).toBe(1);
      expect(screen.getAllByText(/Date/).length).toBe(1);
    });

    it('adds a datetime field with name Date when you select Before option', async () => {
      await selectEvent.select(screen.getByLabelText('Range'), ['Before']);

      expect(screen.getAllByText('Before').length).toBe(1);

      expect(screen.getAllByText(/Date/).length).toBe(1);

    });

    it('adds two datetime field, From and To when you select Between option', async () => {
      await selectEvent.select(screen.getByLabelText('Range'), ['Between']);

      expect(screen.getAllByText('Between').length).toBe(1);

      expect(screen.getAllByText(/From/).length).toBe(1);
      expect(screen.getAllByText(/To/).length).toBe(1);
    });
  });
});
