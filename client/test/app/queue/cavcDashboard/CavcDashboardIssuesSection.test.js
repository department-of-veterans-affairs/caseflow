import React from 'react';
import { render, screen } from '@testing-library/react';
import CavcDashboardIssuesSection from '../../../../app/queue/cavcDashboard/CavcDashboardIssuesSection';

const createDashboardProp = () => {
  return {
    source_request_issues: [{
      id: 1000,
      benefit_type: 'compensation',
      decision_review_type: 'Appeal',
      contested_issue_description: 'A description of issue',
    }],
    cavc_dashboard_issues: [{
      benefit_type: 'education',
      issue_category: {
        label: 'Service Connection'
      },
      disposition: 'Reversed'
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

    expect(screen.getByText(dashboard.source_request_issues[0].benefit_type, { exact: false })).toBeTruthy();
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

    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].benefit_type, { exact: false })).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].issue_category.label)).toBeTruthy();
    expect(Issues.length).toBe(2);
  });
});
