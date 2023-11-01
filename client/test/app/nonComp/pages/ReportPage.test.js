import React from 'react';
import { axe } from 'jest-axe';

import userEvent from '@testing-library/user-event';
import { fireEvent, render, screen } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import ReportPage from 'app/nonComp/pages/ReportPage';
import SearchableDropdown from 'app/components/SearchableDropdown';
import { shallow } from 'enzyme';

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
    render(
      <ReportPage />
    );

    const generateTaskReport = screen.getByRole('button', { name: /Generate task Report/i });
    expect(generateTaskReport).toHaveClass('usa-button-disabled');

    const clearFilters = screen.getByText('Clear filters');
    expect(clearFilters).toHaveClass('usa-button-disabled');
  });
});
