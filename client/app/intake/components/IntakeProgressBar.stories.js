import React from 'react';
import { MemoryRouter, useLocation } from 'react-router';
import { PAGE_PATHS } from '../constants';

import IntakeProgressBar from './IntakeProgressBar';

const RouterDecorator = (Story, { args }) => {
  let pathArray = [PAGE_PATHS.BEGIN];

  if (args.pagePath) {
    pathArray = [args.pagePath];
  }

  return <MemoryRouter initialEntries={pathArray}>
    <Story />
  </MemoryRouter>;
};

export default {
  title: 'Intake/Review/Intake Progress Bar',
  component: IntakeProgressBar,
  decorators: [RouterDecorator],
  args: {
    pagePath: PAGE_PATHS.BEGIN
  },
  argTypes: {
    pagePath: {
      options: [PAGE_PATHS.BEGIN, PAGE_PATHS.SEARCH, PAGE_PATHS.REVIEW, PAGE_PATHS.ADD_ISSUES, PAGE_PATHS.COMPLETED],
      control: { type: 'select' },
    }
  },
};

const Template = (args) => {
  const location = useLocation();

  // Dynamically Adjust the path with the storybook control
  location.pathname = args.pagePath;

  return <IntakeProgressBar {...args} />;
};

export const basic = Template.bind({});
