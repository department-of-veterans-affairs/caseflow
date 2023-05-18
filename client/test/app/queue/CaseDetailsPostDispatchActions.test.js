import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import { CaseDetailsPostDispatchActions } from '../../../app/queue/CaseDetailsPostDispatchActions';
import { appealWithDashboard, amaAppeal } from '../../data/appeals';
import COPY from '../../../COPY';

const mockHistoryPush = jest.fn();

jest.mock('react-router-dom', () => ({
  ...(jest.requireActual('react-router-dom')),
  useHistory: () => ({
    push: mockHistoryPush,
  })
}));

const propToShowCavcDashboard = {
  supportCavcDashboard: true,
};

const propToHideCavcDashboard = {
  supportCavcDashboard: false,
};

const renderCaseDetailsPostDispatchActions = (appeal, props) => {
  return render(<CaseDetailsPostDispatchActions appealId={appeal.externalId} {...props} />);
};

describe('Post Dispatch Actions', () => {
  describe('cavc dashboard button visibility', () => {
    it('shows on the post dispatch component', () => {
      renderCaseDetailsPostDispatchActions(appealWithDashboard, propToShowCavcDashboard);
      expect(screen.queryByRole('button', { name: `${COPY.CAVC_DASHBOARD_BUTTON_TEXT}` })).toBeInTheDocument();
    });

    it('hides when appeal does not have cavc remand with dashboard', () => {
      renderCaseDetailsPostDispatchActions(amaAppeal, propToHideCavcDashboard);
      expect(screen.queryByRole('button', { name: `${COPY.CAVC_DASHBOARD_BUTTON_TEXT}` })).not.toBeInTheDocument();
    });
  });

  describe('clicking cavc dashboard button', () => {
    it('redirects to cavc dashboard page', () => {
      renderCaseDetailsPostDispatchActions(appealWithDashboard, propToShowCavcDashboard);
      fireEvent.click(screen.getByText(COPY.CAVC_DASHBOARD_BUTTON_TEXT, { redirectFromButton: true }));
      expect(mockHistoryPush).toBeCalledTimes(1);
      expect(mockHistoryPush).toBeCalledWith(`/queue/appeals/${appealWithDashboard.externalId}/cavc_dashboard`, expect.objectContaining({ redirectFromButton: true }));
    });
  });
});
