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
import DailyDocketContainer from '../../../app/hearings/DailyDocketContainer';

const store = createStore(hearingsReducers, { dockets: {} }, applyMiddleware(thunk));

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('DailyDocketContainer', () => {
  let wrapper;

  spy(ApiUtil, 'get');

  beforeEach(() => {
    wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/']}>
          <div>
            <DailyDocketContainer veteran_law_judge={{ name: 'me' }} date="2017-06-17"/>
          </div>
        </MemoryRouter>
      </Provider>);
  });

  it('retrieves hearings', () => {
    setTimeout(() => {
      expect(ApiUtil.get.calledOnce).to.be.true;
      ApiUtil.get.restore();
    });
  });

  it('notifies user when no hearings are returned', () => {
    store.dispatch(populateDockets({}));
    expect(wrapper.text()).to.include('You have no upcoming hearings.');
  });

  it('renders loaded hearings', () => {
    store.dispatch(populateDockets({
      '2017-06-17': {
        date: '2017-06-17T17:52:09.742-04:00',
        hearings_hash: [{
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
    expect(wrapper.text()).to.include('Daily Docket');
  });
});
