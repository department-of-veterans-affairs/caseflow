import React from 'react';
import CombinedNonCompReducer from '../reducers';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import { MemoryRouter as Router } from 'react-router-dom';

import thunk from 'redux-thunk';

import SavedSearches from './SavedSearches';

const ReduxDecorator = (Story, { args: { data: { props } } }) => {
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
  title: 'Queue/NonComp/SavedSearches',
  component: SavedSearches,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <SavedSearches
      {...args}
    />
  );
};

export const SavedSearchesTemplate = Template.bind({});

SavedSearchesTemplate.story = {
  name: 'Saved Searches'
};

SavedSearchesTemplate.args = {
  data: {
  }
};

