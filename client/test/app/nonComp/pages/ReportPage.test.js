import React from 'react';
import { axe } from 'jest-axe';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import userEvent from '@testing-library/user-event';
import { render, screen } from '@testing-library/react';
import { createMemoryHistory } from 'history';
import ReportPage from 'app/nonComp/pages/ReportPage';

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
});
