import React from 'react';

import { Tab } from './Tab';
import { Tabs } from './Tabs';

export default {
  title: 'Commons/Components/Tabs',
  component: Tabs,
  decorators: [],
};

export const tabs = () => (
  <Tabs>
    <Tab title="Tab 1" value="1">
      tab 1 content
    </Tab>
    <Tab title="Tab 2" value="2">
      tab 2 content
    </Tab>
  </Tabs>
);

export const manual = () => (
  <Tab.Container active="2">
    <Tab.List>
      <Tab.Item value="1">Tab 1</Tab.Item>
      <Tab.Item value="2">Tab 2</Tab.Item>
      <Tab.Item value="3" disabled>
        Tab 2
      </Tab.Item>
    </Tab.List>
    <Tab.Content>
      <Tab.Panel value="1">lorem all the ipsums</Tab.Panel>
      <Tab.Panel value="2">Content 2</Tab.Panel>
      <Tab.Panel value="3">Content 3</Tab.Panel>
    </Tab.Content>
  </Tab.Container>
);

manual.story = {
  parameters: {
    docs: {
      storyDescription: '',
    },
  },
};
