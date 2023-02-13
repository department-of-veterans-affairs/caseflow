import React from 'react';
import { getByAltText, render, screen, waitFor } from '@testing-library/react';
import { createMockedMembershipRequests, mockedMembershipRequests } from '../../data/membershipRequests';
import MembershipRequestTable from '../../../app/queue/MembershipRequestTable';
import { axe } from 'jest-axe';

describe('MembershipRequestTable', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  const setup = (requests = []) => {
    return render(<MembershipRequestTable requests={requests} />);
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
    expect(screen.queryByText(mockedMembershipRequests[0].note)).toBeNull();
    button.click();

    button = screen.getAllByRole('button', { name: 'Show note' })[0];

    // These strings are based on the mocked data. This test assumes the first two mocked requests have notes.
    expect(button.getAttribute('aria-expanded')).toBe('true');
    waitFor(() => expect(screen.getByText(mockedMembershipRequests[0].note).toBeInTheDocument()));
    expect(screen.queryByText(mockedMembershipRequests[1].note)).toBeNull();

    // Click the button again and check for the text
    button.click();
    button = screen.getAllByRole('button', { name: 'Show note' })[0];
    expect(button.getAttribute('aria-expanded')).toBe('false');
    waitFor(() => expect(screen.getByText(mockedMembershipRequests[0].note)).not.toBeInTheDocument());

    // Get the second note expansion button
    button = screen.getAllByRole('button', { name: 'Show note' })[1];

    button.click();

    // Check for the second note text
    waitFor(() => expect(screen.getByText(mockedMembershipRequests[1].note).toBeInTheDocument()));

    expect(container).toMatchSnapshot();

  });

  it('displays the pagination controls when there are more than 10 membership requests correctly', () => {
    const extraMembershipRequests = createMockedMembershipRequests(10);
    const userName = 'Testy McGee';
    const lastRequest = {
      id: 999,
      name: userName,
      requestedDate: '2023-1-5'
    };

    const requests = [mockedMembershipRequests, extraMembershipRequests, lastRequest].flat();

    setup(requests);

    const paginationButton = screen.getAllByRole('button', {
      name: 'Page 2',
    })[0];

    expect(paginationButton).toBeVisible(true);

    expect(screen.getByText(`View ${requests.length} pending requests`)).toBeVisible(true);

    paginationButton.click();

    waitFor(() => expect(screen.getByText(userName)).toBeInTheDocument());

  });

});

