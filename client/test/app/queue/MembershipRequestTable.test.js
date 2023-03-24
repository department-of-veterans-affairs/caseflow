import React from 'react';
import { fireEvent, render, screen, waitFor } from '@testing-library/react';
import { createMockedMembershipRequests, mockedMembershipRequests } from '../../data/membershipRequests';
import MembershipRequestTable from '../../../app/queue/MembershipRequestTable';
import { axe } from 'jest-axe';

describe('MembershipRequestTable', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (requests = [], actionHandler = jest.fn) => {
    return render(<MembershipRequestTable requests={requests} membershipRequestActionHandler={actionHandler} />);
  };

  it('renders the default state with no requests correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });

  it('renders the default state with mocked membership requests correctly', () => {
    const { container } = setup(mockedMembershipRequests);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y', async () => {
    const { container } = setup(mockedMembershipRequests);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('shows the request note when the expansion button is selected', async () => {
    const { container } = setup(mockedMembershipRequests);

    // Since there are multiple expansion buttons grab the first button and later the second button
    let button = screen.getAllByRole('button', { name: 'Show note' })[0];

    // The first note text should not be visible on the screen
    await expect(screen.queryByText(mockedMembershipRequests[0].note)).toBeNull();
    // await button.click();
    await fireEvent.click(button);

    button = screen.getAllByRole('button', { name: 'Show note' })[0];

    // These strings are based on the mocked data. This test assumes the first two mocked requests have notes.
    expect(button.getAttribute('aria-expanded')).toBe('true');
    await waitFor(() => expect(screen.getByText(mockedMembershipRequests[0].note)).toBeInTheDocument());
    await expect(screen.queryByText(mockedMembershipRequests[1].note)).toBeNull();

    // Click the button again and check for the text
    // await button.click();
    await fireEvent.click(button);
    button = screen.getAllByRole('button', { name: 'Show note' })[0];
    expect(button.getAttribute('aria-expanded')).toBe('false');
    // await waitFor(() => expect(screen.getByText(mockedMembershipRequests[0].note)).not.toBeInTheDocument());
    await expect(screen.queryByText(mockedMembershipRequests[0].note)).toBeNull();

    // Get the second note expansion button
    button = screen.getAllByRole('button', { name: 'Show note' })[1];

    // await button.click();
    await fireEvent.click(button);

    // Check for the second note text
    await waitFor(() => expect(screen.getByText(mockedMembershipRequests[1].note)).toBeInTheDocument());

    expect(container).toMatchSnapshot();

  });

  it('displays the pagination controls when there are more than 10 membership requests correctly', async () => {
    const extraMembershipRequests = createMockedMembershipRequests(12);
    const userName = 'Testy McGee';
    const lastRequest = {
      id: 999,
      userNameWithCssId: userName,
      requestedDate: '2023-1-5'
    };

    const requests = [mockedMembershipRequests, extraMembershipRequests, lastRequest].flat();

    setup(requests);

    const paginationButton = screen.getAllByRole('button', {
      name: 'Page 2',
    })[0];

    expect(paginationButton).toBeVisible(true);

    expect(screen.getByText(`View ${requests.length} pending requests`)).toBeVisible(true);

    await fireEvent.click(paginationButton);
    await waitFor(() => expect(screen.getByText(userName)).toBeInTheDocument());

  });

  it('should call the membershipRequestActionHandler property with args when Approve is clicked', async () => {
    const actionHandler = jest.fn();

    setup(mockedMembershipRequests, actionHandler);

    const selectActionButton = screen.getAllByRole('button', { name: 'Request actions' })[0];

    selectActionButton.click();
    await screen.getByText('Approve').click();

    expect(actionHandler).toHaveBeenCalledWith('1-approved');
  });

  it('should call the membershipRequestActionHandler property with args when Deny is clicked', async () => {
    const actionHandler = jest.fn();

    setup(mockedMembershipRequests, actionHandler);

    const selectActionButton = screen.getAllByRole('button', { name: 'Request actions' })[0];

    selectActionButton.click();
    await screen.getByText('Deny').click();

    expect(actionHandler).toHaveBeenCalledWith('1-denied');
  });

});

