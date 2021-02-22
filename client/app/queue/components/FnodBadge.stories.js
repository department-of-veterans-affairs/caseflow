import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';

import FnodBadge from './FnodBadge';

export default {
  title: 'Commons/Components/Badges/FNOD Badge',
  component: FnodBadge,
  parameters: {
    layout: 'centered',
  },
  args: {
    appeal: {
      veteranAppellantDeceased: true,
      veteranDateOfDeath: '2019-03-17'
    },
    featureToggles: {
      fnod_badge: true
    },
  }
};

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
const store = getStore();

const Template = (args) => (
  <Provider store={store}>
    <FnodBadge {...args} />
  </Provider>
);

export const FNODBadge = Template.bind({});

