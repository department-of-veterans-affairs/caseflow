import React from 'react';

import Button from './Button';

const Template = (args) => <Button {...args} />;

export const Primary = Template.bind({});

export const Secondary = Template.bind({});
Secondary.args = {
  classNames: ['usa-button-secondary'],
};

export const Disabled = Template.bind({});
Disabled.args = {
  disabled: true,
};

export const Link = Template.bind({});
Link.args = {
  linkStyling: true,
};

export const DisabledLink = Template.bind({});
DisabledLink.args = {
  linkStyling: true,
  disabled: true
};

export const Loading = Template.bind({});
Loading.args = {
  name: 'loading',
  loading: true,
  id: 'btn-crt',
  loadingText: 'Loading...',
};

export const Destructive = Template.bind({});
Destructive.args = { redStyling: true, children: 'Danger' };

