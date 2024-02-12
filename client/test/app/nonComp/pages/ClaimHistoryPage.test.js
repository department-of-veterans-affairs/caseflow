import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import { MemoryRouter as Router } from 'react-router-dom';
import ReduxBase from 'app/components/ReduxBase';
import ClaimHistoryPage from 'app/nonComp/pages/ClaimHistoryPage';
import CombinedNonCompReducer, { mapDataToInitialState } from 'app/nonComp/reducers';

import { completeTaskPageData } from '../../../data/queue/nonCompTaskPage/nonCompTaskPageData';

const adminVhaProps = { ...completeTaskPageData };

const renderClaimHistoryPage = (storeValues = {}) => {
  const initialState = mapDataToInitialState(storeValues);

  return render(
    <ReduxBase initialState={initialState} reducer={CombinedNonCompReducer} >
      <Router>
        <ClaimHistoryPage />
      </Router>
    </ReduxBase>
  );
};

describe('ClaimHistoryPage renders correctly for Admin user', () => {
  it('passes a11y testing', async () => {
    const { container } = renderClaimHistoryPage(adminVhaProps);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', () => {
    const { container } = renderClaimHistoryPage(adminVhaProps);

    expect(container).toMatchSnapshot();
  });

  it('displays the claimant\'s name', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByText(adminVhaProps.serverNonComp.task.claimant.name)).toBeInTheDocument();
  });

  it('displays the back link', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByText('< Back to Decision Review')).toBeInTheDocument();
  });

  it('can sort by date and time', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByLabelText('Sort by Date and Time')).toBeInTheDocument();
  });

  it('can sort by user', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByLabelText('Sort by User')).toBeInTheDocument();
  });

  it('can sort by activity', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByLabelText('Sort by Activity')).toBeInTheDocument();
  });

  it('can filter by user', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByLabelText('Filter by User')).toBeInTheDocument();
  });

  it('can filter by activity', () => {
    renderClaimHistoryPage(adminVhaProps);

    expect(screen.getByLabelText('Filter by Activity')).toBeInTheDocument();
  });
});
