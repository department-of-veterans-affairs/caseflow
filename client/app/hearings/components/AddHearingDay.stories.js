import React from 'react';

import { useArgs } from '@storybook/client-api';
import { Provider } from 'react-redux';

import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/hearings/reducers';
import thunk from 'redux-thunk';

import { AddHearingDay } from './AddHearingDay';

const getStore = () => createStore(rootReducer, applyMiddleware(thunk));
const store = getStore();

export default {
  title: 'Hearings/Components/Add Hearing Day',
  component: AddHearingDay,
  decorators: [],
  argTypes: {
    onChange: { action: 'onChange' },
  },
};

const Template = (args) => {
  const [storyArgs, updateStoryArgs] = useArgs();

  const handleChange = (value) => {
    updateStoryArgs({ ...storyArgs, value });
  };

  return (
    <Provider store={store}>
      <AddHearingDay {...args} selectRequestType={handleChange} onSelectedHearingDayChange={handleChange} />
    </Provider>
  );
};

export const Default = Template.bind({});
Default.args = {
};
