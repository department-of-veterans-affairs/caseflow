import React from 'react';
import { axe } from 'jest-axe';

import userEvent from '@testing-library/user-event';
import { fireEvent, render, screen } from '@testing-library/react';
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
      await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event Type/Action']);

      const generateTaskReport = screen.getByRole('button', { name: /Generate task Report/i });
      expect(generateTaskReport).not.toHaveClass('usa-button-disabled');

      const clearFilters = screen.getByText('Clear filters');
      expect(clearFilters).not.toHaveClass('usa-button-disabled');
    });

    it('should list two radio buttons options when Event Type/Action is selected in ReportType', async () => {
      setup();
      await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event / Action']);

      expect(screen.getAllByText('Event Type/Action').length).toBe(1);
      expect(screen.getAllByRole('radio').length).toBe(2);
      expect(screen.getAllByText('All Events / Actions').length).toBe(1);
      expect(screen.getAllByText('Specific Events / Actions').length).toBe(1);
    });

    it('should add 10 checkbox when radio Specific Events/ Actions is clicked', async () => {
      setup();

      await selectEvent.select(screen.getByLabelText('Report Type'), ['Status', 'Event Type/Action']);
      expect(screen.getAllByText('Event Type/Action').length).toBe(1);

      const specificEvents = screen.getAllByText('Specific Events / Actions');

      expect(specificEvents.length).toBe(1);

      fireEvent.click(screen.getByLabelText('Specific Events / Actions'));
      expect(screen.getAllByRole('checkbox').length).toBe(10);

      REPORT_TYPE_CONSTANTS.SPECTIFIC_EVENT_OPTIONS.map((option) => {
        expect(screen.getAllByText(option.label)).toBeTruthy();
      })
    });
  });
});

