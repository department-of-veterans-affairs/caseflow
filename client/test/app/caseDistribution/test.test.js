import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import CaseDistributionTest from 'app/caseDistribution/test';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil', () => ({
  post: jest.fn(),
}));

const defaultProps = {
  acdLevers: [{ id: 1, title: 'Test Lever', item: 'Item 1', control_group: 'Control 1', lever_group: 'Group 1', lever_group_order: 1, description: 'Test Description', data_type: 'Type 1', value: 10, min_value: 0, max_value: 100, unit: 'Units', options: [], is_toggle_active: true, is_disabled_in_ui: false, algorithms_used: 'None', created_at: '2021-01-01', updated_at: '2021-01-02' }],
  acdHistory: [{ id: 1, case_distribution_lever_id: 1, created_at: '2021-01-01', previous_value: 5, update_value: 10, user_css_id: '12345', user_name: 'User 1', lever_title: 'Test Lever', lever_data_type: 'Type 1', lever_unit: 'Units' }],
  returnedAppealJobs: [],
  userDisplayName: 'Test User',
  dropdownUrls: [],
  applicationUrls: [],
  feedbackUrl: '',
  buildDate: '',
};

describe('CaseDistributionTest', () => {
  beforeEach(() => {
    render(<CaseDistributionTest {...defaultProps} />);
  });

  it('renders Clear Ready-to-Distribute Appeals button', () => {
    const button = screen.getByRole('button', { name: /Clear Ready-to-Distribute Appeals/i });
    expect(button).toBeInTheDocument();
  });

  it('button shows loading state when clicked', async () => {
    ApiUtil.post.mockResolvedValueOnce({});
    const button = screen.getByText('Clear Ready-to-Distribute Appeals');

    fireEvent.click(button);

    expect(button).toHaveAttribute('loading', 'true');
    expect(screen.getByText('Clearing Ready-to-Distribute Appeals')).toBeInTheDocument();

    await waitFor(() => {
      expect(button).not.toHaveAttribute('loading');
    });
  });

  it('displays success alert on successful reset', async () => {
    ApiUtil.post.mockResolvedValueOnce({});
    fireEvent.click(screen.getByText('Clear Ready-to-Distribute Appeals'));

    await waitFor(() => {
      expect(screen.getByText('Successfully cleared Ready-to-Distribute Appeals')).toBeInTheDocument();
    });
  });

  it('does not display success alert on failed reset', async () => {
    ApiUtil.post.mockRejectedValueOnce(new Error('Error occurred'));
    fireEvent.click(screen.getByText('Clear Ready-to-Distribute Appeals'));

    await waitFor(() => {
      expect(screen.queryByText('Successfully cleared Ready-to-Distribute Appeals')).not.toBeInTheDocument();
    });
  });

  it('calls resetAllAppeals function on button click', async () => {
    const button = screen.getByText('Clear Ready-to-Distribute Appeals');

    const instance = screen.getByTestId('case-distribution-test').__reactInternalInstance$.return.stateNode;
    jest.spyOn(instance, 'resetAllAppeals');

    fireEvent.click(button);

    expect(instance.resetAllAppeals).toHaveBeenCalled();
  });
});
