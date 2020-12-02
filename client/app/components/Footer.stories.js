import React from 'react';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import { StaticRouter, Route } from 'react-router-dom';
import ReduxBase from '../components/ReduxBase';
import queueReducer from '../queue/reducers';

const storyState = {
  appName: '',
  buildDate: ''
};

const RouterDecorator = (storyFn) => (
  <StaticRouter
    location={{
      pathname: '/',
    }}
  >
    <Route
      path="/"
    >
      {storyFn()}
    </Route>
  </StaticRouter>
);

const ReduxDecorator = (storyFn) => (
  <ReduxBase
    reducer={queueReducer}
    initialState={{ queue: { ...storyState } }}
  >
    {storyFn()}
  </ReduxBase>
);

export default {
  title: 'Commons/Components/Layout/Footer',
  component: Footer,
  parameters: {
    controls: { expanded: true },
  },
  args: {
    appName: '',
    buildDate: '',
    feedbackUrl: ''
  },
  argTypes: {
    appName: { control: 'text' },
    buildDate: { control: 'text' },
    feedbackUrl: { control: 'text' }
  },
  decorators: [RouterDecorator, ReduxDecorator],
};
const Template = (args) => <Footer {...args} />;

export const Basic = Template.bind({});
