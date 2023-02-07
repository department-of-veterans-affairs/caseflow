import React from 'react';
import { render } from '@testing-library/react';
import { CavcDashboardTab } from '../../../../app/queue/cavcDashboard/CavcDashboardTab';

jest.mock('../../../../app/queue/cavcDashboard/CavcDashboardDetails',
  () => () => <mock-details data-testid="testDetails" />
);

describe('cavcDashboardTab', () => {
  it('renders the CavcDashboardDetails component', async () => {
    const { queryByTestId } = render(<CavcDashboardTab />);

    expect(queryByTestId('testDetails')).toBeTruthy();
  });
});
