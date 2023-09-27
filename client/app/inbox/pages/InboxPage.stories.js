import React from 'react';
import { InboxMessagesPage } from './InboxPage';

const legacyAppealLink = '<a href="/queue/appeals/541030342">Veteran ID 541032910</a>';

const appealLink = '<a href="/queue/appeals/7f8db963-c147-4bf6-ad7f-dd2d175d537a">Veteran ID 541032909</a>';

const errorText = '\nCaseflow is having trouble contacting the virtual hearing scheduler.\n';

const supportLink = 'For help, submit a support ticket using <a href="https://yourit.va.gov/">YourIT</a>.\n';

const messages = [
  {
    created_at: '2023-09-22T15:18:39.800-04:00',
    detail_id: 350,
    detail_type: 'LegacyAppeal',
    id: 2,
    message_type: null,
    read_at: null,
    text: `${legacyAppealLink} - Hearing time not updated. ${errorText} ${supportLink}`,
    updated_at: '2023-09-27T09:56:03.747-04:00',
    user_id: 125
  },
  {
    created_at: '2023-09-22T15:18:39.782-04:00',
    detail_id: 1704,
    detail_type: 'Appeal',
    id: 1,
    message_type: null,
    read_at: null,
    text: `${appealLink} - Virtual hearing not scheduled. ${errorText} ${supportLink}`,
    updated_at: '2023-09-27T09:58:44.807-04:00',
    user_id: 125
  }
];

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
  args: { messages, pagination },
  argTypes: {
  },
};

const Template = (args) => {
  return <InboxMessagesPage {...args} />;
};

export const Basic = Template.bind({});
