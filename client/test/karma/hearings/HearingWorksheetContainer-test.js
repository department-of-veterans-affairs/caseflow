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
      streams: {
        appeal_0: {
          issues: {
            issue_0: {
              id: 'issue_0',
              program: 'Compensation',
              issue: 'Service connection',
              levels: 'All Others, 5010 - Arthritis, due to trauma',
              description: 'Left Elbow',
              reopen: true,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: false
            },
            issue_1: {
              id: 'issue_1',
              program: 'Compensation',
              issue: 'Service connection',
              levels: 'All Others, 5010 - Migrane',
              description: 'Frequent headaches, caused by concussion',
              reopen: false,
              remand: true,
              allow: true,
              dismiss: false,
              deny: false,
              vha: true }
          },
          nod: 99,
          soc: 10,
          docs_in_efolder: 88
        }
      },
      contentions: '',
      military_service: '',
      evidence: '',
      comments_for_attorney: ''
    }));
    expect(wrapper.text()).to.include('Hearing Worksheet');
  });
});