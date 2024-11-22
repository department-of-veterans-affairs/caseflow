import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';

import SaveSearchModal from 'app/nonComp/components/ReportPage/SaveSearchModal';
import CombinedNonCompReducer from 'app/nonComp/reducers';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import userSearchParamWithCondition from 'test/data/nonComp/userSearchParamWithConditionData';

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
  title: 'Queue/NonComp/SavedSearches/Save Search Modal',
  component: SaveSearchModal,
  decorators: [ReduxDecorator],
  parameters: {},
  args: {},
  argTypes: {

  },
};

const Template = (args) => {
  return (
    <SaveSearchModal
      {...args}
    />
  );
};

export const SaveSearchModalTemplate = Template.bind({});

SaveSearchModalTemplate.story = {
  name: 'Save Search Modal'
};

SaveSearchModalTemplate.args = {
  data: { nonComp: { businessLineUrl: 'vha' }, savedSearch: userSearchParamWithCondition.savedSearch }
};

