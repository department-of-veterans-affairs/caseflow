import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import HearingBadge from './HearingBadge';

export default {
  title: 'Commons/Components/Badges/Hearing Badge',
  component: HearingBadge,
  parameters: {
    layout: 'centered',
  },
  args: {
    hearing: {
        heldBy: 'ExampleJudgeName',
        disposition: 'ExampleDispositionText',
        date: '2020-01-15',
        type: 'AMA'
    },
  }
};

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
const store = getStore();

const Template = (args) => (
  <Provider store={store}>
    <HearingBadge {...args} />
  </Provider>
);

export const HEARINGBadge = Template.bind({});
