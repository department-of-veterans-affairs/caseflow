import React from 'react';
import { render, screen } from '@testing-library/react';
import { CavcDashboardTab } from '../../../../app/queue/cavcDashboard/CavcDashboardTab';

describe('cavcDashboardTab', () => {
  it('renders with the cavc_docket_number from the remand', async () => {
    const remand = { cavc_docket_number: '12-3456' };

    render(<CavcDashboardTab remand={remand} />);

    expect(screen.getByText(remand.cavc_docket_number, { exact: false })).toBeTruthy();
  });
});
