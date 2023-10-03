import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';

import { InboxMessagesPage } from '../../app/inbox/pages/InboxPage';
import { emptyMessages, allUnreadMessages, oneReadAndOneUnreadMessages } from '../data/inbox';

const successMessage = 'Success! You have no unread messages.';
const messagesRemovedMessage =
  'Messages will remain in the intake box for 120 days. After such time, messages will be removed.';
const defaultProps = {
  messages: emptyMessages,
  pagination: {
    current_page: 1,
    page_size: 50,
    total_items: 2,
    total_pages: 1
  }
};

const setupComponent = (props = {}) => {
  return render(
    <InboxMessagesPage {...defaultProps}{...props} />
  );
};

describe('InboxPage rendering success message', () => {
  it('renders correctly', async () => {
    const { container } = setupComponent();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setupComponent();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

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

describe('renders with data', () => {
  const setupMessages = (messages) => {
    defaultProps.messages = messages;
    setupComponent();
  };

  it('has a message about when the messages are removed', () => {
    setupMessages(allUnreadMessages);

    expect(screen.queryByText(messagesRemovedMessage)).toBeInTheDocument();
  });

  it('renders the correct pagination options', () => {
    setupMessages(allUnreadMessages);

    const paginationProps = defaultProps.pagination;

    const paginationOptions =
      `Viewing ${paginationProps.current_page}-${paginationProps.total_items} of ${paginationProps.total_items} total`;

    expect(screen.queryByText(paginationOptions)).toBeInTheDocument();
  });

  it('renders an inbox with two unread messages', () => {
    setupMessages(allUnreadMessages);

    const trElements = screen.getAllByRole('row');

    expect(trElements.length - 1).toBe(2);

    const unreadButtons = screen.getAllByRole('button', 'Mark as read');

    expect(unreadButtons.length).toBe(2);
  });

  it('renders an inbox with one read and one unread messages', () => {
    setupMessages(oneReadAndOneUnreadMessages);

    const trElements = screen.getAllByRole('row');

    expect(trElements.length - 1).toBe(2);

    expect(screen.getByText('Read Sat Sep 23 2023 at 15:18')).toBeInTheDocument();
    expect(screen.getByText('Mark as read')).toBeInTheDocument();
  });
});
