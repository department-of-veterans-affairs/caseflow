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

const styleDocs = 'All of Caseflow Apps feature a minimal footer that contains the text ' +
                  '“Built with ♡ by the Digital Service at the VA.” and a “Send Feedback” link. Conveniently, ' +
                  'if a developer hovers over the word “Built” they’ll see a tooltip showing the build date of the ' +
                  'app that they are viewing. In styleguide footer, recent build date is based off of “date” in ' +
                  '`build_version.yml`.';

export default {
  title: 'Commons/Components/Layout/Footer',
  component: Footer,
  parameters: {
    controls: { expanded: true },
    docs: {
      storyDescription: styleDocs
    },
  },
  args: {
    appName: '',
    buildDate: '12/25/2020',
    feedbackUrl: ''
  },
  argTypes: {
    appName: {
      control: null
    },
    buildDate: {
      control: 'text'
    },
    feedbackUrl: {
      control: null
    }
  },
  decorators: [RouterDecorator, ReduxDecorator],
};
const Template = (args) => <Footer {...args} />;

export const Basic = Template.bind({});
