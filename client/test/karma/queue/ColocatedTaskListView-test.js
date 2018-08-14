// @flow
import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import ColocatedTaskListView from '../../../app/queue/ColocatedTaskListView';
import { createStore, applyMiddleware } from 'redux';
import moment from 'moment';
import thunk from 'redux-thunk';
import CO_LOCATED_ADMIN_ACTIONS from '../../../constants/CO_LOCATED_ADMIN_ACTIONS.json';
import rootReducer from '../../../app/queue/reducers';
import { onReceiveQueue } from '../../../app/queue/QueueActions';
import { setUserCssId } from '../../../app/queue/uiReducer/uiActions';
import { extractAppealsAndAmaTasks } from '../../../app/queue/utils';

describe('ColocatedTaskListView', () => {
  let wrapperColocatedTaskListView = null;

  const getWrapperColocatedTaskListView = (store) => {
    const wrapper = mount(
      <Provider store={store}>
        <ColocatedTaskListView />
      </Provider>
    );

    return wrapper;
  };

  afterEach(() => {
    if (wrapperColocatedTaskListView) {
      wrapperColocatedTaskListView.unmount();
      wrapperColocatedTaskListView = null;
    }
  });

  const amaTaskTemplate = {
    "id": "8",
    "type": "colocated_tasks",
    "attributes": {
      "type": "ColocatedTask",
      "action": "new_rep_arguments",
      "appeal_id": 5,
      "status": "assigned",
      "assigned_to": {
        "id": 7,
        "station_id": "101",
        "css_id": "BVALSPORER",
        "full_name": "Co-located no cases",
        "email": null,
        "roles": [
          "BVALSPORER"
        ],
        "selected_regional_office": null,
        "display_name": "BVALSPORER (VACO)",
        "judge_css_id": null
      },
      "assigned_by": {
        "id": 1,
        "station_id": "101",
        "css_id": "BVASCASPER1",
        "full_name": "Attorney with cases",
        "email": null,
        "roles": [
          "BVASCASPER1"
        ],
        "selected_regional_office": null,
        "display_name": "BVASCASPER1 (VACO)",
        "judge_css_id": "BVAOSCHOWALT"
      },
      "assigned_at": moment().subtract(47, 'hours').format(),
      "started_at": null,
      "completed_at": null,
      "placed_on_hold_at": null,
      "on_hold_duration": null,
      "instructions": "poa is missing",
      "appeal_type": "Appeal",
      "docket_name": null,
      "case_type": "Original",
      "docket_number": "Missing Docket Number",
      "veteran_name": "Andrew Merica",
      "veteran_file_number": "152003980",
      "external_id": "3bd1567a-4f07-473c-aefc-3738a6cf58fe",
      "aod": false
    }
  };

  const amaTaskWith = ({id, cssIdAssignee}) => ({
    ...amaTaskTemplate,
    id,
    attributes: {
      ...amaTaskTemplate.attributes,
      assigned_to: {
        ...amaTaskTemplate.attributes.assigned_to,
        css_id: cssIdAssignee
      }
    }
  });

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  describe('New tab', () => {
    it('shows only new tasks', () => {
      const userCssId = 'BVALSPORER';
      const taskId = '1';
      const idUnassigned = '5';
      const taskNewAssigned = amaTaskWith({id: taskId, cssIdAssignee: userCssId});
      const taskUnassigned = amaTaskWith({id: idUnassigned, cssIdAssignee: 'NOTBVALSPORER'});
      const amaTasks = [
        taskNewAssigned,
        taskUnassigned
      ];
      const store = getStore();
      store.dispatch(onReceiveQueue(extractAppealsAndAmaTasks((amaTasks))));
      store.dispatch(setUserCssId(userCssId));

      const wrapper = getWrapperColocatedTaskListView(store);

      const cells = wrapper.find('td');

      expect(cells).to.have.length(6);
      const wrappers = [];

      for (let i = 0; i < cells.length; i++) {
        wrappers.push(cells.at(i));
      }
      const [caseDetails, tasks, types, docketNumber, daysWaiting, documents] = wrappers;
      const task = taskNewAssigned;

      expect(caseDetails.text()).to.include(task.attributes.veteran_name);
      expect(caseDetails.text()).to.include(task.attributes.veteran_file_number);
      expect(tasks.text()).to.include(CO_LOCATED_ADMIN_ACTIONS[task.attributes.action]);
      expect(types.text()).to.include(task.attributes.case_type);
      expect(docketNumber.text()).to.include(task.attributes.docket_number);
      expect(daysWaiting.text()).to.equal('1');
      expect(documents.html()).to.include(`/reader/appeal/${task.attributes.external_id}/documents`);
    });
  });

  describe('On hold tab', () => {
    it('shows only on-hold tasks', () => {
      const userCssId = 'BVALSPORER';
      const taskId = '1';
      const idUnassigned = '5';
      const amaTasks = [
        amaTaskWith({id: taskId, cssIdAssignee: userCssId}),
        amaTaskWith({id: idUnassigned, cssIdAssignee: 'NOTBVALSPORER'})
      ];
      const store = getStore();
      store.dispatch(onReceiveQueue(extractAppealsAndAmaTasks((amaTasks))));
      store.dispatch(setUserCssId(userCssId));

      const wrapper = getWrapperColocatedTaskListView(store);
    });
  });
});
