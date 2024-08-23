import React from 'react';
import { render } from '@testing-library/react';
import { CavcDashboardTab } from '../../../../app/queue/cavcDashboard/CavcDashboardTab';
import {Provider} from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { queueWrapper } from 'test/data/stores/queueStore';

const props = {
  dashboard: {
    remand_request_issues: [{
      id: 1000,
      benefit_type: 'compensation',
      description: 'Appeal - A description of issue'
    }],
    cavc_dashboard_issues: [{
      benefit_type: 'education',
      issue_category: 'Service Connection',
      disposition: 'Reversed',
      issue_description: 'Test Issue Description'
    }],
       request_issue_id: 1000,
   cavc_dashboard_dispositions: [{
      disposition: 'Reversed',
    }],
  }
};

describe('cavcDashboardTab', () => {
  it('renders the CavcDashboardDetails and CavcDashboardIssuesSection components', async () => {
    const { queryByTestId } = render(
      <CavcDashboardTab
        { ...props }
      />,
      {
        wrapper: queueWrapper,
      }
    );

    expect(queryByTestId('testDetails')).toBeTruthy();
    expect(queryByTestId('testIssues')).toBeTruthy();
  });
});