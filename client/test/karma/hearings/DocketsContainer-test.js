import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import ApiUtilStub from '../../helpers/ApiUtilStub';
import hearingsReducers from '../../../app/hearings/reducers/index';
import { populateDockets } from '../../../app/hearings/actions/Dockets';
import DocketsContainer from '../../../app/hearings/DocketsContainer';

const store = createStore(hearingsReducers, { dockets: {} }, applyMiddleware(thunk));

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DocketsContainer', () => {
  let wrapper;

  beforeEach(() => {
    ApiUtilStub.beforeEach();

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
    ApiUtilStub.afterEach();
  });

  it('retrieves dockets', () => {
    setTimeout(() => {
      expect(ApiUtilStub.apiGet.calledOnce).to.be.true;
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
        hearings_array: [{
          id: 1,
          appeal_id: 68468,
          appellant_last_first_mi: 'VanBuren, James A.',
          date: '2017-06-30T14:03:42.714Z',
          representative_name: 'Military Order of the Purple Heart',
          request_type: 'CO',
          user_id: 9,
          vacols_id: 'f10b9ed6a',
          vbms_id: '3bf55b922',
          venue: {
            city: 'Baltimore',
            state: 'MD',
            timezone: 'America/New_York'
          },
          worksheet_comments_for_attorney: 'Look for knee-related medical records',
          worksheet_contentions: 'The veteran believes their knee is hurt',
          worksheet_evidence: 'Medical exam occurred on 10/10/2008',
          worksheet_military_service: null,
          worksheet_witness: 'Jane Doe attended'
        }],
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
