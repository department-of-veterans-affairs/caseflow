import React from 'react';
import { render, screen } from '@testing-library/react';

import { InboxMessagesPage } from '../../app/inbox/pages/InboxPage';
import { emptyMessages, allUnreadMessages } from '../data/inbox';

const successMessage = 'Success! You have no unread messages.';

const defaultProps = {
  messages: emptyMessages,
  pagination: {
    current_page: 1,
    page_size: 50,
    total_items: 2,
    total_pages: 1
  }
};

describe('InboxPage rendering success message', () => {
  const setupComponent = (props = {}) => {
    return render(
      <InboxMessagesPage {...defaultProps}{...props} />
    );
  };

  it('renders an empty inbox with a the success message', () => {
    setupComponent();

    expect(screen.queryByText(successMessage)).toBeInTheDocument();
  });

  it('renders an inbox with unread messages and no success message', () => {
    defaultProps.messages = allUnreadMessages;
    setupComponent();

    expect(screen.queryByText(successMessage)).not.toBeInTheDocument();
  });
});
