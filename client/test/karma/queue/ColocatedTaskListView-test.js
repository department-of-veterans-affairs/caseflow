import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import ColocatedTaskListView from '../../../app/queue/ColocatedTaskListView';
import { createStore, applyMiddleware } from 'redux';
import moment from 'moment';
import thunk from 'redux-thunk';
import rootReducer from '../../../app/queue/reducers';
import { onReceiveQueue, receiveNewDocumentsForTask, errorFetchingDocumentCount, setAppealDocCount, setQueueConfig }
  from '../../../app/queue/QueueActions';
import { setUserCssId } from '../../../app/queue/uiReducer/uiActions';
import { BrowserRouter } from 'react-router-dom';

describe('ColocatedTaskListView', () => {
  let wrapperColocatedTaskListView = null;

  const getWrapperColocatedTaskListView = (store) => {
    const wrapper = mount(
      <Provider store={store}>
        <BrowserRouter>
          <ColocatedTaskListView />
        </BrowserRouter>
      </Provider>
    );

    return wrapper;
  };

  let momentNow = null;

  before(() => {
    momentNow = moment.now;
    moment.now = () => 100000;
  });

  after(() => {
    moment.now = momentNow;
  });

  afterEach(() => {
    if (wrapperColocatedTaskListView) {
      wrapperColocatedTaskListView.unmount();
      wrapperColocatedTaskListView = null;
    }
  });

  const getAmaTaskTemplate = () => ({
    uniqueId: '1',
    type: 'Task',
    isLegacy: false,
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 5,
    externalAppealId: '3bd1567a-4f07-473c-aefc-3738a6cf58fe',
    assignedOn: moment().subtract(47, 'hours').
      format(),
    closedAt: null,
    assignedTo: {
      cssId: 'BVALSPORER',
      name: 'Judge with cases',
      type: 'User',
      isOrganization: true,
      id: 7
    },
    assignedBy: {
      firstName: 'Attorney',
      lastName: 'cases',
      cssId: 'BVASCASPER1',
      pgId: 1
    },
    taskId: '8',
    label: 'New rep arguments',
    documentId: null,
    workProduct: null,
    previousTaskAssignedOn: null,
    placedOnHoldAt: null,
    onHoldDuration: null,
    decisionPreparedBy: null,
    availableActions: [],
    hideFromQueueTableView: false,
    hideFromCaseTimeline: false,
    hideFromTaskSnapshot: false,
    closestRegionalOffice: ''
  });

  const appealTemplate = {
    id: 5,
    type: 'Appeal',
    isLegacyAppeal: false,
    externalId: '3bd1567a-4f07-473c-aefc-3738a6cf58fe',
    docketName: null,
    caseType: 'Original',
    isAdvancedOnDocket: false,
    issueCount: 2,
    docketNumber: 'Missing Docket Number',
    assignedJudge: null,
    assignedAttorney: null,
    veteranFullName: 'Andrew Van Buren',
    veteranFileNumber: '152003980',
    isPaperCase: null
  };

  const amaTaskWith = ({ cssIdAssignee, ...rest }) => {
    const amaTaskTemplate = getAmaTaskTemplate();

    return ({
      ...amaTaskTemplate,
      ...rest,
      assignedTo: {
        ...amaTaskTemplate.assignedTo,
        cssId: cssIdAssignee
      }
    });
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const queueConfig = {
    "active_tab": "assigned",
    "table_title": "Your cases",
    "tabs": [
        {
            "allow_bulk_assign": false,
            "columns": [
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "hearingBadgeColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "detailsColumn"
                },
                {
                    "filter_options": [
                        {
                            "displayText": "Stayed appeal (3)",
                            "value": "StayedAppealColocatedTask"
                        },
                        {
                            "displayText": "Hearing clarification (3)",
                            "value": "HearingClarificationColocatedTask"
                        },
                        {
                            "displayText": "New rep arguments (2)",
                            "value": "NewRepArgumentsColocatedTask"
                        },
                        {
                            "displayText": "Extension (2)",
                            "value": "ExtensionColocatedTask"
                        },
                        {
                            "displayText": "IHP (2)",
                            "value": "IhpColocatedTask"
                        },
                        {
                            "displayText": "Retired VLJ (2)",
                            "value": "RetiredVljColocatedTask"
                        },
                        {
                            "displayText": "Address verification (2)",
                            "value": "AddressVerificationColocatedTask"
                        }
                    ],
                    "filterable": true,
                    "name": "taskColumn"
                },
                {
                    "filter_options": [
                        {
                            "displayText": "Original (16)",
                            "value": "Original"
                        }
                    ],
                    "filterable": true,
                    "name": "typeColumn"
                },
                {
                    "filter_options": [
                        {
                            "displayText": "Evidence (14)",
                            "value": "evidence_submission"
                        },
                        {
                            "displayText": "Direct Review (1)",
                            "value": "direct_review"
                        },
                        {
                            "displayText": "Legacy (1)",
                            "value": "legacy"
                        }
                    ],
                    "filterable": true,
                    "name": "docketNumberColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "daysWaitingColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "readerLinkColumn"
                }
            ],
            "description": "Cases assigned to you:",
            "label": "Assigned (%d)",
            "name": "assigned_person",
            "task_page_count": 2,
            "task_page_endpoint_base_path": "task_pages?tab=assigned_person",
            "tasks": [],
            "total_task_count": 16
        },
        {
            "allow_bulk_assign": false,
            "columns": [
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "hearingBadgeColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "detailsColumn"
                },
                {
                    "filter_options": [],
                    "filterable": true,
                    "name": "taskColumn"
                },
                {
                    "filter_options": [],
                    "filterable": true,
                    "name": "typeColumn"
                },
                {
                    "filter_options": [],
                    "filterable": true,
                    "name": "docketNumberColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "daysOnHoldColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "readerLinkWithNewDocIconColumn"
                }
            ],
            "description": "Cases on hold (will return to \"Assigned\" tab when hold is completed):",
            "label": "On hold (%d)",
            "name": "on_hold_person",
            "task_page_count": 0,
            "task_page_endpoint_base_path": "task_pages?tab=on_hold_person",
            "tasks": [],
            "total_task_count": 0
        },
        {
            "allow_bulk_assign": false,
            "columns": [
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "hearingBadgeColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "detailsColumn"
                },
                {
                    "filter_options": [],
                    "filterable": true,
                    "name": "taskColumn"
                },
                {
                    "filter_options": [],
                    "filterable": true,
                    "name": "typeColumn"
                },
                {
                    "filter_options": [],
                    "filterable": true,
                    "name": "docketNumberColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "completedDateColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "completedToNameColumn"
                },
                {
                    "filter_options": [],
                    "filterable": false,
                    "name": "readerLinkColumn"
                }
            ],
            "description": "Cases completed (last two weeks):",
            "label": "Completed",
            "name": "completed_person",
            "task_page_count": 0,
            "task_page_endpoint_base_path": "task_pages?tab=completed_person",
            "tasks": [],
            "total_task_count": 0
        }
    ],
    "tasks_per_page": 15,
    "use_task_pages_api": false
};

  /* eslint-disable no-unused-expressions */
  describe('Assigned tab', () => {
    it('shows only new tasks and tasks with a completed hold', () => {
      const daysOnHold = 31;
      const taskNewAssigned = amaTaskWith({ id: '1',
        cssIdAssignee: 'BVALSPORER' });
      const taskUnassigned = amaTaskWith({ id: '5',
        cssIdAssignee: 'NOTBVALSPORER' });
      const completedHoldTask = amaTaskWith({
        id: '6',
        cssIdAssignee: 'BVALSPORER',
        assignedOn: moment().subtract(daysOnHold + 0.5, 'days'),
        placedOnHoldAt: moment().subtract(daysOnHold, 'days'),
        onHoldDuration: daysOnHold - 1
      });
      const appeal = appealTemplate;

      const tasks = {};
      const amaTasks = {
        [taskNewAssigned.id]: taskNewAssigned,
        [taskUnassigned.id]: taskUnassigned,
        [completedHoldTask.id]: completedHoldTask
      };
      const appeals = {
        [appeal.id]: appeal
      };

      const store = getStore();

      store.dispatch(onReceiveQueue({ tasks,
        amaTasks,
        appeals }));
      store.dispatch(setUserCssId(taskNewAssigned.assignedTo.cssId));
      store.dispatch(setQueueConfig(queueConfig));

      const wrapper = getWrapperColocatedTaskListView(store);

      const cells = wrapper.find('td');

      expect(cells).to.have.length(14);
      const wrappers = [];

      for (let i = 0; i < cells.length / 2; i++) {
        wrappers.push(cells.at(i));
      }
      const [hearings, caseDetails, columnTasks, types, docketNumber, daysWaiting, documents] = wrappers;
      const task = taskNewAssigned;

      expect(hearings.text()).to.include('');
      expect(caseDetails.text()).to.include(appeal.veteranFullName);
      expect(caseDetails.text()).to.include(appeal.veteranFullName);
      expect(caseDetails.text()).to.include(appeal.veteranFileNumber);
      expect(columnTasks.text()).to.include(task.label);
      expect(types.text()).to.include(appeal.caseType);
      expect(docketNumber.text()).to.include(appeal.docketNumber);
      expect(daysWaiting.text()).to.equal('1');
      expect(documents.html()).to.include(`/reader/appeal/${task.externalAppealId}/documents`);
      expect(documents.text()).to.include('Loading number of docs...');

      store.dispatch(errorFetchingDocumentCount(task.externalAppealId));
      expect(wrapper.find('td').at(6).
        text()).to.include('Failed to Load');

      store.dispatch(setAppealDocCount(task.externalAppealId, 5));
      expect(wrapper.find('td').at(6).
        text()).to.include('5');

      const onHoldDaysWaiting = cells.at(12);

      expect(onHoldDaysWaiting.text()).to.equal(daysOnHold.toString());
      expect(onHoldDaysWaiting.find('.cf-red-text').length).to.eq(1);
      expect(onHoldDaysWaiting.find('.cf-continuous-progress-bar-warning').length).to.eq(1);
    });
  });

  describe('On hold tab', () => {
    it('shows only on-hold tasks', () => {
      const task = amaTaskWith({
        id: '1',
        cssIdAssignee: 'BVALSPORER',
        placedOnHoldAt: moment().subtract(2, 'days'),
        onHoldDuration: 30,
        status: 'on_hold'
      });
      const taskNotAssigned = amaTaskWith({
        ...task,
        id: '5',
        cssIdAssignee: 'NOTBVALSPORER'
      });
      const taskWithNewDocs = {
        ...task,
        id: '4',
        externalAppealId: '44'
      };
      const taskNew = amaTaskWith({
        id: '6',
        cssIdAssignee: task.assignedTo.cssId
      });
      const appeal = appealTemplate;
      const appealWithNewDocs = {
        ...appeal,
        id: '6',
        externalId: taskWithNewDocs.externalAppealId
      };

      const tasks = {};
      const amaTasks = {
        [task.id]: task,
        [taskNotAssigned.id]: taskNotAssigned,
        [taskWithNewDocs.id]: taskWithNewDocs,
        [taskNew.id]: taskNew
      };
      const appeals = {
        [appeal.id]: appeal,
        [appealWithNewDocs.id]: appealWithNewDocs
      };
      const store = getStore();

      store.dispatch(onReceiveQueue({ tasks,
        amaTasks,
        appeals }));
      store.dispatch(setUserCssId(task.assignedTo.cssId));
      store.dispatch(receiveNewDocumentsForTask({
        taskId: taskWithNewDocs.taskId,
        newDocuments: [{}]
      }));
      store.dispatch(setQueueConfig(queueConfig));

      const wrapper = getWrapperColocatedTaskListView(store);

      wrapper.find('[aria-label="On hold (2) tab window"]').simulate('click');

      expect(wrapper.find('[aria-label="On hold (2) tab window"] #NEW').length).to.eq(0);

      const cells = wrapper.find('td');

      expect(cells).to.have.length(14);
      const wrappers = [];

      for (let i = 0; i < cells.length / 2; i++) {
        wrappers.push(cells.at(i));
      }
      const [hearings, caseDetails, columnTasks, types, docketNumber, daysOnHold, documents] = wrappers;

      expect(hearings.text()).to.include('');
      expect(caseDetails.text()).to.include(appeal.veteranFullName);
      expect(caseDetails.text()).to.include(appeal.veteranFileNumber);
      expect(columnTasks.text()).to.include(task.label);
      expect(types.text()).to.include(appeal.caseType);
      expect(docketNumber.text()).to.include(appeal.docketNumber);
      expect(daysOnHold.text()).to.equal('1 of 30');
      expect(daysOnHold.find('.cf-continuous-progress-bar').length).to.eq(1);
      expect(documents.html()).to.include(`/reader/appeal/${task.externalAppealId}/documents`);
    });
  });
});
/* eslint-enable no-unused-expressions */
