import React from 'react';
import { axe } from 'jest-axe';

import userEvent from '@testing-library/user-event';
import { fireEvent, getAllByRole, render, screen, waitFor } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import ReportPage from 'app/nonComp/pages/ReportPage';
import selectEvent from 'react-select-event';

import REPORT_TYPE_CONSTANTS from 'constants/REPORT_TYPE_CONSTANTS';

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
    setup();

    const generateTaskReport = screen.getByRole('button', { name: /Generate task Report/i });

    expect(generateTaskReport).toHaveClass('usa-button-disabled');

    const clearFilters = screen.getByText('Clear filters');

    expect(clearFilters).toHaveClass('usa-button-disabled');
  });

  describe('ReportType Dropdown', () => {
    it('should enable clearFilter and generate buttons when any option is selected', async () => {
      setup();
      await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event / Action']);

      const generateTaskReport = screen.getByRole('button', { name: /Generate task Report/i });

      expect(generateTaskReport).not.toHaveClass('usa-button-disabled');

      const clearFilters = screen.getByText('Clear filters');

      expect(clearFilters).not.toHaveClass('usa-button-disabled');
    });

    it('should list two radio buttons options when Event / Action is selected in ReportType', async () => {
      setup();
      await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event / Action']);

      expect(screen.getAllByText('Event / Action').length).toBe(1);
      expect(screen.getAllByRole('radio').length).toBe(2);
      expect(screen.getAllByText('All Events / Actions').length).toBe(1);
      expect(screen.getAllByText('Specific Events / Actions').length).toBe(1);
    });

    it('should add 10 checkbox when radio Specific Events/ Actions is clicked', async () => {
      setup();

      await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event / Action']);
      expect(screen.getAllByText('Event / Action').length).toBe(1);

      const specificEvents = screen.getAllByText('Specific Events / Actions');

      expect(specificEvents.length).toBe(1);

      fireEvent.click(screen.getByLabelText('Specific Events / Actions'));
      expect(screen.getAllByRole('checkbox').length).toBe(10);

      REPORT_TYPE_CONSTANTS.SPECTIFIC_EVENT_OPTIONS.map((option) => {
        expect(screen.getAllByText(option.label)).toBeTruthy();
      });
    });
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

    it('adds a datetime field with name Date when you select After Or Before option', async () => {
      const dropdownName = screen.getByLabelText(/Range/);

      await selectEvent.select(dropdownName, ['After']);

      expect(screen.getAllByText('After').length).toBe(1);
      expect(screen.queryByText('Date')).toBeInTheDocument();
    });

    it('adds a datetime field with name Date when you select Before option', async () => {
      const dropdownName = screen.getByLabelText(/Range/);

      await selectEvent.select(dropdownName, ['Before']);

      expect(screen.getAllByText('Before').length).toBe(1);
      expect(screen.queryByText('Date')).toBeInTheDocument();
    });

    it('adds two datetime field, From and To when you select Between option', async () => {
      const dropdownName = screen.getByLabelText(/Range/);

      await selectEvent.select(dropdownName, ['Between']);

      expect(screen.getAllByText('Between').length).toBe(1);

      expect(screen.getAllByText(/From/).length).toBe(1);
      expect(screen.getAllByText(/To/).length).toBe(1);

    });

    it('should not display any date time input if options Last 7 days, Last 30 days, Last 365 days', async () => {
      ['Last 30 Days', 'Last 7 Days', 'Last 365 Days'].forEach(async (option) => {

        const dropdownName = screen.getByLabelText(/Range/);

        await selectEvent.select(dropdownName, [option]);

        await waitFor(() => {
          expect(screen.getAllByText([option]).length).toBe(1);
        });

        await waitFor(() => {
          expect(screen.queryByText('Date')).not.toBeInTheDocument();
          expect(screen.queryByText('From')).not.toBeInTheDocument();
          expect(screen.queryByText('To')).not.toBeInTheDocument();
        });
      });
    });
  });
});
