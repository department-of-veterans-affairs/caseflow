import React from 'react';
import { GithubIcon } from '../../app/components/icons/fontAwesome/GithubIcon';

export default {
  title: 'Commons/Components/Icons/GithubIcon',
  component: GithubIcon,
};

const Template = (args) => <GithubIcon {...args} />;

export const Default = Template.bind({});
Default.parameters = {
  docs: {
    description: {
      component: 'This is a Font Awesome Icon and gets no props.',
    },
  },
};
