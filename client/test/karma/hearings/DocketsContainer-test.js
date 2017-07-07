import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { spy } from 'sinon';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import ApiUtil from '../../../app/util/ApiUtil';
import hearingsReducers from '../../../app/hearings/reducers/index';
import { populateDockets } from '../../../app/hearings/actions/Dockets';
import DocketsContainer from '../../../app/hearings/DocketsContainer';

const store = createStore(hearingsReducers, { dockets: {} }, applyMiddleware(thunk));

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DocketsContainer', () => {
  let wrapper;

  spy(ApiUtil, 'get');

  beforeEach(() => {
    wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/']}>
          <div>
            <DocketsContainer veteran_law_judge={{ name: 'me' }} />
          </div>
        </MemoryRouter>
      </Provider>);
  });

  afterEach(() => {
    wrapper = null;
  });

  it('retrieves dockets', () => {
    setTimeout(() => {
      expect(ApiUtil.get.calledOnce).to.be.true;
      ApiUtil.get.restore();
    });
  });

  it('notifies user when no dockets are returned', () => {
    store.dispatch(populateDockets({}));
    expect(wrapper.text()).to.include('You have no upcoming hearings.');
  });

  it('renders loaded dockets', () => {
    store.dispatch(populateDockets({
      '2017-06-17': {
        date: '2017-06-17T17:52:09.742-04:00',
        hearings_hash: [],
        type: 'central_office',
        venue: {
          city: 'Baltimore',
          state: 'MD',
          timezone: 'America/New_York'
        }
      }
    }));
    expect(wrapper.text()).to.include('Upcoming Hearing Days');
  });
});
