import React from 'react';
import { render, screen, waitForElementToBeRemoved } from '@testing-library/react';
import { CavcDashboard } from '../../../../app/queue/cavcDashboard/CavcDashboard';
import { amaAppeal } from '../../../data/appeals';
import COPY from '../../../../COPY';

jest.mock('../../../../app/queue/cavcDashboard/CavcDashboardTab');

const renderCavcDashboard = async (appealData, shouldResolvePromise) => {
  const cavcRemands = [
    { cavc_docket_number: '12-3456' }
  ];

  // rejecting the redux action creator promises to cause setError(true) on the dashboard
  const promiseResult = shouldResolvePromise ?
    jest.fn(() => Promise.resolve(true)) :
    jest.fn(() => Promise.reject(false));

  // required props must be explicitly passed in since we are not connecting to redux
  const props = {
    appealId: appealData.id,
    appealDetails: appealData,
    cavcRemands,
    fetchAppealDetails: promiseResult,
    fetchCavcDecisionReasons: promiseResult,
    fetchCavcSelectionBases: promiseResult,
    fetchInitialDashboardData: promiseResult
  };

  return render(<CavcDashboard {...props} />);
};

describe('cavcDashboard', () => {
  it('Displays loading screen component when loading', async () => {
    await renderCavcDashboard(amaAppeal, true);

    expect(screen.getByText(COPY.CAVC_DASHBOARD_LOADING_SCREEN_TEXT)).toBeTruthy();
  });

  it('Header renders with appellant full name', async () => {
    await renderCavcDashboard(amaAppeal, true);
    await waitForElementToBeRemoved(document.querySelector('svg'));

    expect(screen.getByText(`CAVC appeals for ${amaAppeal.appellantFullName}`)).toBeTruthy();
  });

  it('Displays error status message when error occurs', async () => {
    await renderCavcDashboard(amaAppeal, false);
    await waitForElementToBeRemoved(document.querySelector('svg'));

    expect(screen.getByText(COPY.CAVC_DASHBOARD_LOADING_FAILURE_TEXT)).toBeTruthy();
  });
});
