import React from 'react';
import { render, screen } from '@testing-library/react';
import CavcDashboardIssuesSection from '../../../../app/queue/cavcDashboard/CavcDashboardIssuesSection';

jest.mock('../../../../app/queue/cavcDashboard/CavcDecisionReasons',
  () => () => <mock-details data-testid="testDecisionReasons" />
);

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useDispatch: () => jest.fn().mockImplementation(() => Promise.resolve(true)),
  // useSelector is only used to get state for selectionBases and see if array length is > 0
  useSelector: () => jest.fn().mockImplementation(() => Promise.resolve([1, 2, 3]))
}));

const createDashboardProp = (hasIssues) => {
  if (hasIssues) {
    return {
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
      cavc_dashboard_dispositions: [{
        request_issue_id: 1000,
        disposition: 'Reversed',
      }]
    };
  }

  return {
    remand_request_issues: [],
    cavc_dashboard_issues: [],
    cavc_dashboard_dispositions: []
  };
};

const renderCavcDashboardIssuesSection = async (dashboard, userCanEdit = true) => {
  const props = { dashboard, userCanEdit };

  return render(<CavcDashboardIssuesSection {...props} />);
};

describe('CavcDashboardIssuesSection', () => {

  it('displays correct values with remand_request_issues', async () => {
    const dashboard = createDashboardProp(true);

    await renderCavcDashboardIssuesSection(dashboard);
    const Issues = [...document.querySelectorAll('li')];

    expect(screen.getAllByText(dashboard.remand_request_issues[0].benefit_type, { exact: false })).toBeTruthy();
    expect(screen.getAllByText(dashboard.remand_request_issues[0].description)).toBeTruthy();
    expect(Issues.length).toBe(2);

  });

  it('displays correct values with cavc_dashboard_issues', async () => {
    const dashboard = createDashboardProp(true);

    await renderCavcDashboardIssuesSection(dashboard);
    const Issues = [...document.querySelectorAll('li')];

    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].benefit_type, { exact: false })).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].issue_category)).toBeTruthy();
    expect(screen.getByText(dashboard.cavc_dashboard_issues[0].issue_description, { exact: false })).toBeTruthy();
    expect(Issues.length).toBe(2);
  });

  it('renders with no remand_request_issues present', async () => {
    const dashboard = createDashboardProp(false);

    await renderCavcDashboardIssuesSection(dashboard);

    expect(screen.getByText('Issues')).toBeTruthy();
    expect(screen.getByText('Dispositions')).toBeTruthy();
    expect(document.querySelector('ol').childElementCount).toBe(0);
  });
});
