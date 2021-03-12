import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../reducers';
import thunk from 'redux-thunk';
import OvertimeBadge from 'app/queue/components/OvertimeBadge';
import { Provider } from 'react-redux';
import { mount } from 'enzyme';
import { setCanViewOvertimeStatus } from 'app/queue/uiReducer/uiActions';

describe('OvertimeBadge', () => {
  const defaultAppeal = {
    canViewOvertimeStatus: true,
    overtime: true
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupOvertimeBadge = (store) => {
    return mount(
      <Provider store={store}>
        <OvertimeBadge
          appeal={defaultAppeal}
        />
      </Provider> 
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    store.dispatch(setCanViewOvertimeStatus(true));
    const component = setupOvertimeBadge(store);

    expect(component).toMatchSnapshot();
  });
});
