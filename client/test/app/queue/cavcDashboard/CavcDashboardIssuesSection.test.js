import React from 'react';
import { render, screen } from '@testing-library/react';
import CavcDashboardIssuesSection from '../../../../app/queue/cavcDashboard/CavcDashboardIssuesSection';

jest.mock('../../../../app/queue/cavcDashboard/CavcDecisionReasons',
  () => () => <mock-details data-testid="testDecisionReasons" />
);

const createDashboardProp = () => {
  return {
    source_request_issues: [{
      id: 1000,
      benefit_type: 'compensation',
      decision_review_type: 'Appeal',
      contested_issue_description: 'A description of issue',
    }],
    cavc_dashboard_issues: [{
      benefit_type: 'Review',
      issue_category: 'Service Connection',
    }],
    cavc_dashboard_dispositions: [{
      request_issue_id: 1000,
      disposition: 'Reversed',
    }]
  };
};

const renderCavcDashboardIssuesSection = async (dashboard) => {
  const props = { dashboard };

  return render(<CavcDashboardIssuesSection {...props} />);
};

describe('CavcDashboardIssuesSection', () => {

  it('displays correct values with source_request_issues', async () => {
    const dashboard = createDashboardProp();

    await renderCavcDashboardIssuesSection(dashboard);
    const Issues = [...document.querySelectorAll('li')];

    expect(screen.getByText(dashboard.source_request_issues[0].benefit_type)).toBeTruthy();
    expect(screen.getByText(
      // eslint-disable-next-line max-len
      `${dashboard.source_request_issues[0].decision_review_type } - ${ dashboard.source_request_issues[0].contested_issue_description}`
    )).toBeTruthy();
    expect(Issues.length).toBe(2);

  });

  it('displays correct values with cavc_dashboard_issues', async () => {
    const dashboard = createDashboardProp();

    await renderCavcDashboardIssuesSection(dashboard);
    const Issues = [...document.querySelectorAll('li')];

    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].benefit_type)).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].issue_category)).toBeTruthy();
    expect(Issues.length).toBe(2);
  });
});
