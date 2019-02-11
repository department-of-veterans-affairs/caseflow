import React from 'react';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from '../../../app/queue/reducers';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
// import reducers from './reducers';
// import { BrowserRouter } from 'react-router-dom';
import { expect } from 'chai';
import { mount } from 'enzyme';

import HearingBadge from '../../../app/queue/components/HearingBadge';

describe('HearingBadge', () => {
  context('base', () => {
    const getHearingBadge = (store, hearing) => {
      return mount(
        <Provider store={store}>
          <HearingBadge hearing={hearing} />
        </Provider>
      );
    };
    const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

    it('doesn\'t show if there are no hearings', () => {
      const store = getStore();
      const wrapper = getHearingBadge(store, undefined);

      expect(wrapper.find('div')).to.have.length(0);
    });
  });
});
