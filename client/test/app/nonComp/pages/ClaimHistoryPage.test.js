import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';

import ReduxBase from 'app/components/ReduxBase';
import ClaimHistoryPage from 'app/nonComp/pages/ClaimHistoryPage';
import CombinedNonCompReducer, { mapDataToInitialState } from 'app/nonComp/reducers';

import { completeTaskPageData } from '../../../data/queue/nonCompTaskPage/nonCompTaskPageData';

const adminVhaProps = { ...completeTaskPageData };

const renderClaimHistoryPage = (storeValues = {}) => {
  const initialState = mapDataToInitialState(storeValues);

  return render(
    <ReduxBase initialState={initialState} reducer={CombinedNonCompReducer} >
      <ClaimHistoryPage />
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
});
