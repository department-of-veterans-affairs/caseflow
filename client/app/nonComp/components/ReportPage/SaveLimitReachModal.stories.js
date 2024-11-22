import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';

import SaveLimitReachedModal from 'app/nonComp/components/ReportPage/SaveLimitReachedModal';
import CombinedNonCompReducer from 'app/nonComp/reducers';
import { applyMiddleware, createStore, compose } from 'redux';

import thunk from 'redux-thunk';
import savedSearchesData from 'test/data/nonComp/savedSearchesData';

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
  title: 'Queue/NonComp/SavedSearches/Save Limit Reach Modal',
  component: SaveLimitReachedModal,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <SaveLimitReachedModal
      {...args}
    />
  );
};

export const SaveLimitReachedModalTemplate = Template.bind({});

SaveLimitReachedModalTemplate.story = {
  name: 'Save Limit Reach Modal'
};

SaveLimitReachedModalTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: savedSearchesData.savedSearches }
};

