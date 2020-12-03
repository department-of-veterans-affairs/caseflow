import React from 'react';
import NavigationBar from './NavigationBar';
import PerformanceDegradationBanner from './PerformanceDegradationBanner';
import { LOGO_COLORS } from '../constants/AppConstants';
import { StaticRouter, Route } from 'react-router-dom';
import ReduxBase from '../components/ReduxBase';
import queueReducer, { initialState } from '../queue/reducers';

const storyState = {
  appName: '',
  key: '/queue',
  extraBanner: <PerformanceDegradationBanner showBanner={false} />,
  userDisplayName: '',
  dropdownUrls: [{
    title: 'Queue',
    link: '/queue',
    target: '#top',
    border: false
  }],
  topMessage: null,
  defaultUrl: '/path/to/desired/route'

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
    initialState={{ queue: { ...initialState, ...storyState } }}
  >
    {storyFn()}
  </ReduxBase>
);

const styleDocs = 'The Navigation Bar is a simple white bar that sits on top of every application. ' +
                  'Our navigation bar is non-sticky and scrolls out of view as the user scrolls down ' +
                  'the page. It includes branding for the specific application on the left; a Caseflow ' +
                  'logo and application name (see Application Branding for more details). ' +
                  'The Navigation Bar also includes the user menu on the right. ' +
                  'This menu indicates which user is signed in and contains links to submit feedback, ' +
                  'view the application’s help page, see newly launched features, and log out. ' +
                  'The navigation bar is a total of `90px` tall with a `1px border-bottom` colored `grey-lighter`.';

export default {
  title: 'Commons/Components/Layout/NavigationBar',
  component: NavigationBar,
  parameters: {
    controls: { expanded: true },
    docs: {
      storyDescription: styleDocs
    },
  },
  args: {
    appName: 'Navigation Bar Demo',
    userDisplayName: 'Tom Brady',
    logoProps: {
      accentColor: LOGO_COLORS.QUEUE.ACCENT,
      overlapColor: LOGO_COLORS.QUEUE.OVERLAP
    }
  },
  argTypes: {
    appName: { description: 'Name of application.', control: 'text' },
    userDisplayName: { description: 'Display name of the current User.', control: 'text' },
    logoProps: { description: 'Props passed down to the `CaseflowLogo` component.' }
  },
  decorators: [RouterDecorator, ReduxDecorator],
};
const Template = (args) => <NavigationBar {...args} />;

export const Basic = Template.bind({});
