import React from 'react';

import { action } from '@storybook/addon-actions';

import { Tab } from './Tab';
import { Tabs } from './Tabs';

export default {
  title: 'Commons/Components/Tabs',
  component: Tabs,
  decorators: [
    (storyFn) => (
      <div
        style={{ minHeight: '250px', maxWidth: '800px', padding: '20px 30px' }}
      >
        {storyFn()}
      </div>
    ),
  ],
};

export const tabs = (args) => (
  <Tabs {...args}>
    <Tab title="Tab 1" value="1">
      Tab 1 Content
    </Tab>
    <Tab title="Tab 2" value="2">
      Tab 2 Content
    </Tab>
  </Tabs>
);

export const Disabled = (args) => (
  <Tabs {...args}>
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

export const DefaultTab = (args) => (
  <Tabs {...args}>
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
DefaultTab.args = { active: '2' };

export const FullWidth = (args) => (
  <Tabs {...args}>
    <Tab title="Tab 1" value="1">
      <h4>Tab 1 Content</h4>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua.
      </p>
    </Tab>
    <Tab title="Tab 2" value="2">
      <h4>Tab 2 Content</h4>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua.
      </p>
    </Tab>
    <Tab title="Tab 3" value="3">
      <h4>Tab 3 Content</h4>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua.
      </p>
    </Tab>
  </Tabs>
);
FullWidth.args = { fullWidth: true };

export const MountOnEnter = (args) => (
  <Tabs {...args}>
    <Tab title="Tab 1" value="1">
      Tab 1 content (rendered when tab is first activated)
    </Tab>
    <Tab title="Tab 2" value="2">
      Tab 2 content (rendered when tab is first activated)
    </Tab>
    <Tab title="Tab 3" value="3">
      Tab 3 content (rendered when tab is first activated)
    </Tab>
  </Tabs>
);
MountOnEnter.args = { mountOnEnter: true };

export const UnmountOnExit = (args) => (
  <Tabs {...args}>
    <Tab title="Tab 1" value="1">
      Tab 1 content (only rendered when tab is currently active)
    </Tab>
    <Tab title="Tab 2" value="2">
      Tab 2 content (only rendered when tab is currently active)
    </Tab>
    <Tab title="Tab 3" value="3">
      Tab 3 content (only rendered when tab is currently active)
    </Tab>
  </Tabs>
);
UnmountOnExit.args = { mountOnEnter: true, unmountOnExit: true };

export const Manual = (args) => (
  <Tab.Container {...args}>
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
Manual.args = { active: '2' };
Manual.argTypes = { onChange: { action: 'onChange' } };

Manual.parameters = {
  docs: {
    storyDescription: [
      'One can use the lower-level components to build a more customized layout.',
      'Note that `<Tab.List>` and `<Tab.Panel>` must be wrapped in a `<Tab.Container>`',
    ].join(' '),
  },
};
