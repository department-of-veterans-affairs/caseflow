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
      Tab 1 Content
    </Tab>
    <Tab title="Tab 2" value="2">
      Tab 2 Content
    </Tab>
  </Tabs>
);

export const disabled = () => (
  <Tabs>
    <Tab title="Tab 1" value="1">
      Tab 1 Content
    </Tab>
    <Tab title="Tab 2" value="2">
      Tab 2 Content
    </Tab>
    <Tab title="Tab 3" value="3" disabled>
      Inaccessible content
    </Tab>
    <Tab title="Tab 4" value="4">
      Tab 4 Content
    </Tab>
  </Tabs>
);

export const defaultTab = () => (
  <Tabs active="2">
    <Tab title="Tab 1" value="1">
      Tab 1 Content
    </Tab>
    <Tab title="Tab 2" value="2">
      Tab 2 Content
    </Tab>
    <Tab title="Tab 3" value="3">
      Tab 3 Content
    </Tab>
  </Tabs>
);

export const fullWidth = () => (
  <div
    style={{
      maxWidth: '800px',
      padding: '20px',
    }}
  >
    <Tabs fullWidth>
      <Tab title="Tab 1" value="1">
        <h4>Tab 1 Content</h4>
        <p>
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </p>
      </Tab>
      <Tab title="Tab 2" value="2">
        <h4>Tab 2 Content</h4>
        <p>
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </p>
      </Tab>
      <Tab title="Tab 3" value="3">
        <h4>Tab 3 Content</h4>
        <p>
          Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
          eiusmod tempor incididunt ut labore et dolore magna aliqua.
        </p>
      </Tab>
    </Tabs>
  </div>
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
