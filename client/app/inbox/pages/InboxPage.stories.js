import React from 'react';
import { InboxMessagesPage } from './InboxPage';
import { allUnreadMessages, oneReadOneUnreadMessages, emptyMessages } from '../../../test/data/inbox';

// const emptyMessages = [];

const pagination = {
  current_page: 1,
  page_size: 50,
  total_items: 2,
  total_pages: 1
};

export default {
  title: 'Inbox',
  component: InboxMessagesPage,
  decorators: [],
  parameters: {},
  args: { messages: emptyMessages, pagination },
  argTypes: {
  },
};

const EmptyTemplate = (args) => {

  return <InboxMessagesPage {...args} />;
};

export const EmptyInbox = EmptyTemplate.bind({});

const allUnreadMessagesTemplate = (args) => {
  args.messages = allUnreadMessages;

  return <InboxMessagesPage {...args} />;
};

export const AllUnreadMessages = allUnreadMessagesTemplate.bind({});

const oneReadOneUnreadMessagesTemplate = (args) => {
  args.messages = oneReadOneUnreadMessages;

  return <InboxMessagesPage {...args} />;
};

export const OneReadOneUnreadMessages = oneReadOneUnreadMessagesTemplate.bind({});
