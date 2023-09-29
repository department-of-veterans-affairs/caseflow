import React from 'react';
import {render, screen } from '@testing-library/react';

import { InboxMessagesPage } from '../../app/inbox/pages/InboxPage';
import { emptyMessages } from '../data/inbox';

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

describe('InboxMessagesPage', () => {
  const setupComponent = (props = {}) => {
    return render(
      <InboxMessagesPage {...defaultProps}{...props} />
    );
  };

  it('renders an empty inbox with a message', () => {
    setupComponent();

    expect(screen.getByText(successMessage)).toBeInTheDocument();
  });
});
