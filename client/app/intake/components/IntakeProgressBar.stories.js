import React from 'react';
import { MemoryRouter } from 'react-router';
import { PAGE_PATHS } from '../constants';

import IntakeProgressBar from './IntakeProgressBar';

const RouterDecorator = (Story, { parameters }) => {
  let pathArray = ['/'];

  if (parameters.pagePath) {
    pathArray = [parameters.pagePath];
  }

  return <MemoryRouter initialEntries={pathArray}>
    <Story />
  </MemoryRouter>;
};

export default {
  title: 'Intake/Review/Intake Progress Bar',
  component: IntakeProgressBar,
  decorators: [RouterDecorator],
  parameters: {
    pagePath: PAGE_PATHS.BEGIN
  },
  argTypes: {
  },
};

const Template = (args) => (<IntakeProgressBar {...args} />);

export const SelectForm = Template.bind({});

export const Search = Template.bind({});
export const Review = Template.bind({});
export const AddIssues = Template.bind({});
export const Confirmation = Template.bind({});

Search.parameters = { pagePath: PAGE_PATHS.SEARCH };
Review.parameters = { pagePath: PAGE_PATHS.REVIEW };
AddIssues.parameters = { pagePath: PAGE_PATHS.ADD_ISSUES };
Confirmation.parameters = { pagePath: PAGE_PATHS.COMPLETED };
