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
import { amaTasksReceived } from '../../../app/queue/QueueActions';
import { setUserCssId } from '../../../app/queue/uiReducer/uiActions';

describe('ColocatedTaskListView', () => {
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

  describe('New tab', () => {
    it('shows only new tasks', () => {
      const userCssId = 'BVALSPORER';
      const taskId = '1';
      const idUnassigned = '5';
      const amaTasks = {
        [taskId]: amaTaskWith({id: taskId, cssIdAssignee: userCssId}),
        [idUnassigned]: amaTaskWith({id: idUnassigned, cssIdAssignee: 'NOTBVALSPORER'})
      };
      const store = createStore(
        rootReducer,
        applyMiddleware(thunk)
      );
      store.dispatch(amaTasksReceived(amaTasks));
      store.dispatch(setUserCssId(userCssId));

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
      const task = amaTasks[taskId];

      expect(caseDetails.text()).to.include(task.attributes.veteran_name);
      expect(caseDetails.text()).to.include(task.attributes.veteran_file_number);
      expect(tasks.text()).to.include(CO_LOCATED_ADMIN_ACTIONS[task.attributes.action]);
      expect(types.text()).to.include(task.attributes.case_type);
      expect(docketNumber.text()).to.include(task.attributes.docket_number);
      expect(daysWaiting.text()).to.equal('1');
      expect(documents.html()).to.include(`/reader/appeal/${task.attributes.external_id}/documents`);
    });
  });
});
