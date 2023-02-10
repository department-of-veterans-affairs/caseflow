import React from 'react';
import { render } from '@testing-library/react';
import { CavcDashboardTab } from '../../../../app/queue/cavcDashboard/CavcDashboardTab';

jest.mock('../../../../app/queue/cavcDashboard/CavcDashboardDetails',
  () => () => <mock-details data-testid="testDetails" />
);

jest.mock('../../../../app/queue/cavcDashboard/CavcDashboardIssuesSection',
  () => () => <mock-details data-testid="testIssues" />
);

describe('cavcDashboardTab', () => {
  it('renders the CavcDashboardDetails and CavcDashboardIssuesSection components', async () => {
    const { queryByTestId } = render(<CavcDashboardTab />);

    expect(queryByTestId('testDetails')).toBeTruthy();
    expect(queryByTestId('testIssues')).toBeTruthy();
  });
});
