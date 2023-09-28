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

const Template = (args) => {

  return <InboxMessagesPage {...args} />;
};

export const EmptyInbox = Template.bind({});

export const AllUnreadMessages = Template.bind({});

AllUnreadMessages.args = {
  messages: allUnreadMessages
};

export const OneReadOneUnreadMessages = Template.bind({});

OneReadOneUnreadMessages.args = {
  messages: oneReadOneUnreadMessages
};
