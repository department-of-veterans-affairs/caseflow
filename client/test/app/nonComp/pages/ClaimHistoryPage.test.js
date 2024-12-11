import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import { MemoryRouter as Router } from 'react-router-dom';
import ClaimHistoryPage from 'app/nonComp/pages/ClaimHistoryPage';
import { Provider } from 'react-redux';
import ApiUtil from 'app/util/ApiUtil';
import createNonCompStore from '../nonCompStoreCreator';

import individualClaimHistoryData from '../../../data/nonComp/individualClaimHistoryData';
const renderClaimHistoryPage = (storeValues = individualClaimHistoryData) => {
  const store = createNonCompStore(storeValues);

  return render(
    <Provider store={store} >
      <Router>
        <ClaimHistoryPage />
      </Router>
    </Provider>
  );
};

describe('ClaimHistoryPage renders correctly for Admin user', () => {
  beforeEach(() => {
    ApiUtil.get = jest.fn().mockResolvedValue({ body: [] });
  });

  it('passes a11y testing', async () => {
    const { container } = renderClaimHistoryPage();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders correctly', () => {
    const { container } = renderClaimHistoryPage();

    expect(container).toMatchSnapshot();
  });

  it('displays the claimant\'s name', () => {
    renderClaimHistoryPage();

    expect(screen.getByText(individualClaimHistoryData.nonComp.task.claimant.name)).toBeInTheDocument();
  });

  it('displays the back link', () => {
    renderClaimHistoryPage();

    expect(screen.getByText('< Back to Decision Review')).toBeInTheDocument();
  });

  it('can sort by date and time', () => {
    renderClaimHistoryPage();

    expect(screen.getByLabelText('Sort by Date and Time')).toBeInTheDocument();
  });

  it('can sort by user', () => {
    renderClaimHistoryPage();

    expect(screen.getByLabelText('Sort by User')).toBeInTheDocument();
  });

  it('can sort by activity', () => {
    renderClaimHistoryPage();

    expect(screen.getByLabelText('Sort by Activity')).toBeInTheDocument();
  });

  it('can filter by user', () => {
    renderClaimHistoryPage();

    expect(screen.getByLabelText('Filter by User')).toBeInTheDocument();
  });

  it('can filter by activity', () => {
    renderClaimHistoryPage();

    expect(screen.getByLabelText('Filter by Activity')).toBeInTheDocument();
  });
});
