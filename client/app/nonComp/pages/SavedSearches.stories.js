import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';

import SavedSearches from './SavedSearches';
import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';

const ReduxDecorator = (Story, { args: { data: { props } } }) => {
  const store = createNonCompStore(props);

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

