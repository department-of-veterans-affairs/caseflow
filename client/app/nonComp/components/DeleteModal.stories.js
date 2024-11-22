import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';

import DeleteModal from 'app/nonComp/components/DeleteModal';
import CombinedNonCompReducer from 'app/nonComp/reducers';
import { applyMiddleware, createStore, compose } from 'redux';

import thunk from 'redux-thunk';

const search = {
  savedSearch: {
    selectedSearch: {
      createdAt: '2024-11-14T08:58:19.706-05:00',
      description: 'Ad explicabo earum. Corrupti excepturi reiciendis. Qui eaque dolorem.',
      id: '61',
      name: 'Search to be deleted',
      savedSearch: { },
      type: 'saved_search',
      user: {
      }
    }
  }
};

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
  title: 'Queue/NonComp/SavedSearches/Delete Modal',
  component: DeleteModal,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <DeleteModal
      {...args}
    />
  );
};

export const DeleteModalTemplate = Template.bind({});

DeleteModalTemplate.story = {
  name: 'Delete Modal'
};

DeleteModalTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: search.savedSearch }
};

