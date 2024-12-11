import React from 'react';
import { Provider } from 'react-redux';
import { MemoryRouter as Router } from 'react-router-dom';
import createNonCompStore from 'test/app/nonComp/nonCompStoreCreator';

const ReduxDecorator = (Story, options) => {
  const props = {
    ...options.args.data
  };

  const store = createNonCompStore(props);

  return <Provider store={store} >
    <Router>
      <Story />
    </Router>
  </Provider>;
};

export default ReduxDecorator;
