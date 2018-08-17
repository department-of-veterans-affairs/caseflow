import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import ColocatedTaskListView from '../../../app/queue/ColocatedTaskListView';
import { createStore, applyMiddleware } from 'redux';
import moment from 'moment';
import thunk from 'redux-thunk';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';

describe('ColocatedTaskListView', () => {
  xit('shows only new tasks', () => {
    const userCssId = 'BVALSPORER';
    const taskId = '1';
    const state = {
      queue: {
        amaTasks: {
          [taskId]: {
            id: taskId,
            attributes: {
              action: 'ihp',
              aod: false,
              assigned_at: moment().subtract(47, 'hours').
                format(),
              assigned_to: {
                css_id: userCssId
              },
              case_type: 'Original',
              docket_number: '123456',
              external_id: '12345678',
              veteran_file_number: '123456789',
              veteran_name: 'Jane Smith'
            }
          }
        },
        docCountForAppeal: {},
        newDocsForAppeal: {}
      },
      ui: {
        userCssId
      }
    };
    const store = createStore(
      (xState) => xState,
      state,
      applyMiddleware(thunk)
    );

    const wrapper = mount(
      <Provider store={store}>
        <ColocatedTaskListView />
      </Provider>
    );

    const cells = wrapper.find('td');

    expect(cells).to.have.length(6);
    const wrappers = [];

    for (let i = 0; i < cells.length; i++) {
      wrappers.push(cells.at(i));
    }
    const [caseDetails, tasks, types, docketNumber, daysWaiting, documents] = wrappers;
    const task = state.queue.amaTasks[taskId];

    expect(caseDetails.text()).to.include(task.attributes.veteran_name);
    expect(caseDetails.text()).to.include(task.attributes.veteran_file_number);
    expect(tasks.text()).to.include(CO_LOCATED_ADMIN_ACTIONS[task.attributes.action]);
    expect(types.text()).to.include(task.attributes.case_type);
    expect(docketNumber.text()).to.include(task.attributes.docket_number);
    expect(daysWaiting.text()).to.equal('1');
    expect(documents.html()).to.include(`/reader/appeal/${task.attributes.external_id}/documents`);
  });
});
