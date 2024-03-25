import React from 'react';
import CombinedNonCompReducer from '../reducers';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import { MemoryRouter as Router } from 'react-router-dom';

import thunk from 'redux-thunk';

import ClaimHistoryPage from './ClaimHistoryPage';

import individualClaimHistoryData from 'test/data/nonComp/individualClaimHistoryData';

const ReduxDecorator = (Story, options) => {
  const props = {
    ...options.args.data
  };

  const store = createStore(
    CombinedNonCompReducer,
    props,
    compose(applyMiddleware(thunk))
  );

  return <Provider store={store} >
    <Router>
      <Story />
    </Router>
  </Provider>;
};

export default {
  title: 'Queue/NonComp/ClaimHistoryPage',
  component: ClaimHistoryPage,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <ClaimHistoryPage
      {...args}
    />
  );
};

export const ClaimHistoryPageTemplate = Template.bind({});

ClaimHistoryPageTemplate.story = {
  name: 'Completed High level Claims'
};

ClaimHistoryPageTemplate.args = {
  data: {
    ...individualClaimHistoryData
  }
};

