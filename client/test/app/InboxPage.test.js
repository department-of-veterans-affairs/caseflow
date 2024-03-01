import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';

import { InboxMessagesPage } from '../../app/inbox/pages/InboxPage';
import { emptyMessages, allUnreadMessages, oneReadAndOneUnreadMessages } from '../data/inbox';

const defaultProps = {
  messages: emptyMessages,
  pagination: {
    current_page: 1,
    page_size: 50,
    total_items: 2,
    total_pages: 1
  }
};

const paginationProps = defaultProps.pagination;

const successMessage = 'Success! You have no unread messages.';
const messagesRemovedMessage =
  'Messages will remain in the intake box for 120 days. After such time, messages will be removed.';
const paginationOptions =
  `Viewing ${paginationProps.current_page}-${paginationProps.total_items} of ${paginationProps.total_items} total`;

const setupComponent = (props = {}) => {
  return render(
    <InboxMessagesPage {...defaultProps}{...props} />
  );
};

describe('InboxPage rendering with an empty inbox', () => {
  it('renders correctly', async () => {
    const { container } = setupComponent();

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = setupComponent();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('renders a the success message', () => {
    setupComponent();

    expect(screen.getByText(successMessage)).toBeInTheDocument();
  });
});

describe('InboxPage rendering with data', () => {
  const setupMessages = (messages) => {
    defaultProps.messages = messages;
    setupComponent();
  };

  it('renders no success message', () => {
    setupMessages(allUnreadMessages);

    expect(screen.queryByText(successMessage)).not.toBeInTheDocument();
  });

  it('has a message about when the messages are removed', () => {
    setupMessages(allUnreadMessages);

    expect(screen.getByText(messagesRemovedMessage)).toBeInTheDocument();
  });

  it('renders the correct pagination options', () => {
    setupMessages(allUnreadMessages);

    expect(screen.getByText(paginationOptions)).toBeInTheDocument();
  });

  it('renders an inbox with two unread messages', () => {
    setupMessages(allUnreadMessages);

    const trElements = screen.getAllByRole('row');

    expect(trElements.length - 1).toBe(2);

    const unreadButtons = screen.getAllByRole('button');

    expect(unreadButtons.length).toBe(2);
    for (let button of unreadButtons) {
      expect(button).toBeEnabled();
    }
  });

  it('renders an inbox with one read and one unread messages', () => {
    setupMessages(oneReadAndOneUnreadMessages);

    const trElements = screen.getAllByRole('row');

    expect(trElements.length - 1).toBe(2);

    const allButtons = screen.getAllByRole('button');

    expect(allButtons[0]).toBeInTheDocument();
    expect(allButtons[0]).not.toBeEnabled();
  });
});
