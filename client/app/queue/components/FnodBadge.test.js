import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import FnodBadge from 'app/queue/components/FnodBadge';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';

describe('FnodBadge', () => {
  const defaultAppeal = {
    veteranAppellantDeceased: true,
    veteranDateOfDeath: '2019-03-17'
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupFnodBadge = (store) => {
    return mount(
      <Provider store={store}>
        <FnodBadge
          appeal={defaultAppeal}
        />
      </Provider> 
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const component = setupFnodBadge(store);

    expect(component).toMatchSnapshot();
  });
});
