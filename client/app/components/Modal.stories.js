import React from 'react';

import { action } from '@storybook/addon-actions';

import Modal from './Modal';
import TextField from './TextField';

export default {
  title: 'Commons/Components/Modal',
  component: Modal,
  parameters: {
    controls: { expanded: true },
    docs: {
      inlineStories: false,
      iframeHeight: 600,
    },
  },

  args: {
    title: 'Modal Title',
  },
  argTypes: {
    closeHandler: { action: 'closed' },
  },
};

const Template = (args) => {
  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: (e) => {
        action('close')(e.target);
      },
    },
    {
      classNames: ['usa-button', 'usa-button-secondary'],
      name: 'Proceed with action',
      onClick: (e) => {
        action('submit')(e.target);
      },
    },
  ];

  return (
    <Modal {...args} buttons={buttons}>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod
        tempor incididunt ut labore et dolore magna aliqua.
      </p>
      <TextField
        onChange={() => {}}
        label="This is a text box for the modal."
        name="Text Box"
        placeholder="Enter something related to this modal!"
      />
    </Modal>
  );
};

export const Basic = Template.bind({});

export const Icon = Template.bind({});
Icon.args = {
  icon: 'warning'
};
