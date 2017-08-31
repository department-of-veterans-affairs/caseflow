import React from 'react';
import { MemoryRouter } from 'react-router-dom';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { createStore, applyMiddleware } from 'redux';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import ApiUtilStub from '../../helpers/ApiUtilStub';
import hearingsReducers from '../../../app/hearings/reducers/index';
import { populateWorksheet } from '../../../app/hearings/actions/Dockets';
import HearingWorksheetContainer from '../../../app/hearings/HearingWorksheetContainer';

const store = createStore(hearingsReducers, { dockets: {} }, applyMiddleware(thunk));

/* eslint-disable camelcase */
/* eslint-disable no-unused-expressions */
/* eslint-disable max-statements */
describe('HearingWorksheetContainer', () => {
  let wrapper;

  beforeEach(() => {
    ApiUtilStub.beforeEach();

    wrapper = mount(
      <Provider store={store}>
        <MemoryRouter initialEntries={['/']}>
          <div>
            <HearingWorksheetContainer
              veteran_law_judge={{ name: 'me' }}
              date="2017-01-01"
              hearingId="1"
            />
          </div>
        </MemoryRouter>
      </Provider>);
  });

  afterEach(() => {
    ApiUtilStub.afterEach();
  });

  it('retrieves a worksheet', () => {
    setTimeout(() => {
      expect(ApiUtilStub.apiGet.calledOnce).to.be.true;
    });
  });

  it('renders loaded worksheet', () => {
    store.dispatch(populateWorksheet({
      veteran: {},
      appeal: {},
      streams: {}
    }));
    expect(wrapper.text()).to.include('Hearing Worksheet');
  });
});
