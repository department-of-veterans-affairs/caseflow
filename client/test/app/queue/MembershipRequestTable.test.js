import React from 'react';
import { render, screen } from '@testing-library/react';
import { mockedMembershipRequests } from '../../data/membershipRequests';
import MembershipRequestTable from '../../../app/queue/MembershipRequestTable';

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

  it('shows the request note when the expansion button is selected', () => {
    setup(mockedMembershipRequests);

    // Since there are multiple expansion buttons grab the first button and later the second button
    let button = screen.getAllByRole('button', { name: 'Show note' })[0];

    button.click();

    button = screen.getAllByRole('button', { name: 'Show note' })[0];

    // These strings are based on the mocked data. This will have to be updated if the mocked data changes.
    expect(screen.getByText('Please process this request as soon as possible')).toBeVisible();
    expect(screen.queryByText('This request can be postponed for now.')).toBeNull();
    expect(button.getAttribute('aria-expanded')).toBe('true');

    // Click the button again and check for the text
    button.click();
    expect(screen.queryByText('Please process this request as soon as possible')).toBeNull();

    // Get the second note expansion button
    button = screen.getAllByRole('button', { name: 'Show note' })[1];

    button.click();

    // Check for the second note text
    expect(screen.getByText('This request can be postponed for now.')).toBeVisible();

  });

});

