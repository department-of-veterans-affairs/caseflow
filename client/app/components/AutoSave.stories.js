import React from 'react';

import AutoSave from './AutoSave';

export default {
  title: 'Commons/Components/AutoSave',
  component: AutoSave,
  parameters: {
    controls: { expanded: true },
    docs: {
      inlineStories: false,
      iframeHeight: 600,
    },
  },

  args: {
    isSaving: true,
    timeSaved: '11:00am',
  },
  argTypes: {
    save: { action: 'save' },
  }
};

// It hides on the right side of the storybook display, this 50% div pulls it into the center
const Template = (args) => <div style={{ width: '50%' }}><AutoSave {...args} /></div>;

export const Saving = Template.bind({});
export const Failure = Template.bind();
Failure.args = { isSaving: false, saveFailed: true };
export const Success = Template.bind();
Success.args = { isSaving: false };
