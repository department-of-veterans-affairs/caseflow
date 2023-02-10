import React from 'react';
import { render, screen } from '@testing-library/react';
import CavcDashboardIssuesSection from '../../../../app/queue/cavcDashboard/CavcDashboardIssuesSection';

const createRemandProp = () => {
  return {
    source_request_issues: [{
      benefit_type: 'compensation',
      decision_review_type: 'Appeal',
      contested_issue_description: 'A description of issue',
    }],
    cavc_dashboard_issues: [{
      benefit_type: 'Review',
      issue_category: 'Service Connection',
    }],
  };
};

const renderCavcDashboardIssuesSection = async (remand) => {
  const props = { remand };

  return render(<CavcDashboardIssuesSection {...props} />);
};

describe('CavcDashboardIssuesSection', () => {

  it('displays correct values with source_request_issues', async () => {
    const remand = createRemandProp();

    await renderCavcDashboardIssuesSection(remand);
    const Issues = [...document.querySelectorAll('li')];

    expect(screen.getByText(remand.source_request_issues[0].benefit_type)).toBeTruthy();
    expect(screen.getByText(
      // eslint-disable-next-line max-len
      `${remand.source_request_issues[0].decision_review_type } - ${ remand.source_request_issues[0].contested_issue_description}`
    )).toBeTruthy();
    expect(Issues.length).toBe(2);

  });

  it('displays correct values with cavc_dashboard_issues', async () => {
    const remand = createRemandProp();

    await renderCavcDashboardIssuesSection(remand);
    const Issues = [...document.querySelectorAll('li')];

    expect(screen.getByText(remand.cavc_dashboard_issues[0].benefit_type)).toBeTruthy();
    expect(screen.getByText(remand.cavc_dashboard_issues[0].issue_category)).toBeTruthy();
    expect(Issues.length).toBe(2);
  });
});
