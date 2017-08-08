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
import DailyDocketContainer from '../../../app/hearings/DailyDocketContainer';

/*
import TextareaContainer from '../../../app/hearings/TextareaContainer';
import DropdownContainer from '../../../app/hearings/DropdownContainer';
import CheckboxContainer from '../../../app/hearings/CheckboxContainer';
*/
import Checkbox from '../../../app/components/Checkbox';
import SearchableDropdown from '../../../app/components/SearchableDropdown';

const store = createStore(hearingsReducers, { dockets: {} }, applyMiddleware(thunk));

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
/* eslint-disable newline-per-chained-call */
describe('DailyDocketContainer', () => {
  let wrapper;

  beforeEach(() => {
    ApiUtilStub.beforeEach();

    wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/']}>
          <div>
            <DailyDocketContainer veteran_law_judge={{ name: 'me' }} date="2017-06-17"/>
          </div>
        </MemoryRouter>
      </Provider>);
  });

  afterEach(() => {
    ApiUtilStub.afterEach();
  });

  it('retrieves hearings', () => {
    setTimeout(() => {
      expect(ApiUtilStub.apiGet.calledOnce).to.be.true;
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
          id: 1,
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

  it('updates a docket', () => {
    wrapper.find('textarea').simulate('change', { target: { value: 'My new value' } });
    wrapper.find(SearchableDropdown).at(0).simulate('change', { target: { value: 'held' } });
    wrapper.find(SearchableDropdown).at(1).simulate('change', { target: { value: '60' } });
    wrapper.find(SearchableDropdown).at(2).simulate('change', { target: { value: 'grant' } });
    wrapper.find(Checkbox).simulate('click');
    setTimeout(() => {
      let state = store.getState();
      let hearing = state.dockets['2017-06-17'].hearings_hash[0];

      expect(hearing.notes).to.equal('My new value');
      expect(hearing.disposition).to.equal('held');
      expect(hearing.hold_open).to.equal('60');
      expect(hearing.grant).to.equal('grant');
      expect(hearing.transcript_requested).to.equal(true);
    }, 1000);
  });

});
