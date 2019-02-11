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
import { onReceiveQueue, receiveNewDocuments } from '../../../app/queue/QueueActions';
import { setUserCssId } from '../../../app/queue/uiReducer/uiActions';
import { BrowserRouter } from 'react-router-dom';
import type { Task, BasicAppeal } from '../../../app/queue/types/models';

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

  const getAmaTaskTemplate = (): Task => ({
    uniqueId: '1',
    type: 'GenericTask',
    isLegacy: false,
    appealType: 'Appeal',
    addedByCssId: null,
    appealId: 5,
    externalAppealId: '3bd1567a-4f07-473c-aefc-3738a6cf58fe',
    assignedOn: moment().subtract(47, 'hours').
      format(),
    closedAt: null,
    dueOn: null,
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
    label: 'new_rep_arguments',
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

  const appealTemplate: BasicAppeal = {
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

  describe('New tab', () => {
    it('shows only new tasks', () => {
      const taskNewAssigned = amaTaskWith({ id: '1',
        cssIdAssignee: 'BVALSPORER' });
      const taskUnassigned = amaTaskWith({ id: '5',
        cssIdAssignee: 'NOTBVALSPORER' });
      const appeal = appealTemplate;

      const tasks = {};
      const amaTasks = {
        [taskNewAssigned.id]: taskNewAssigned,
        [taskUnassigned.id]: taskUnassigned
      };
      const appeals = {
        [appeal.id]: appeal
      };

      const store = getStore();

      store.dispatch(onReceiveQueue({ tasks,
        amaTasks,
        appeals }));
      store.dispatch(setUserCssId(taskNewAssigned.assignedTo.cssId));

      const wrapper = getWrapperColocatedTaskListView(store);

      const cells = wrapper.find('td');

      expect(cells).to.have.length(6);
      const wrappers = [];

      for (let i = 0; i < cells.length; i++) {
        wrappers.push(cells.at(i));
      }
      const [caseDetails, columnTasks, types, docketNumber, daysWaiting, documents] = wrappers;
      const task = taskNewAssigned;

      expect(caseDetails.text()).to.include(appeal.veteranFullName);
      expect(caseDetails.text()).to.include(appeal.veteranFullName);
      expect(caseDetails.text()).to.include(appeal.veteranFileNumber);
      expect(columnTasks.text()).to.include(CO_LOCATED_ADMIN_ACTIONS[task.label]);
      expect(types.text()).to.include(appeal.caseType);
      expect(docketNumber.text()).to.include(appeal.docketNumber);
      expect(daysWaiting.text()).to.equal('1');
      expect(documents.html()).to.include(`/reader/appeal/${task.externalAppealId}/documents`);
    });
  });

  describe('Pending tab', () => {
    it('shows only pending tasks', () => {
      const task = amaTaskWith({
        id: '1',
        cssIdAssignee: 'BVALSPORER',
        placedOnHoldAt: moment().subtract(30, 'days'),
        onHoldDuration: 30
      });
      const taskWithNewDocs = amaTaskWith({
        id: '4',
        cssIdAssignee: 'BVALSPORER',
        externalAppealId: '44',
        placedOnHoldAt: moment().subtract(2, 'days'),
        onHoldDuration: 30
      });
      const taskNotAssigned = amaTaskWith({
        ...task,
        id: '5',
        cssIdAssignee: 'NOTBVALSPORER'
      });
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
      store.dispatch(receiveNewDocuments({
        appealId: appealWithNewDocs.externalId,
        newDocuments: [{}]
      }));

      const wrapper = getWrapperColocatedTaskListView(store);

      wrapper.find('[aria-label="Pending action (1) tab window"]').simulate('click');

      const cells = wrapper.find('td');

      expect(cells).to.have.length(6);
      const wrappers = [];

      for (let i = 0; i < cells.length; i++) {
        wrappers.push(cells.at(i));
      }
      {
        const [daysOnHold, documents] = wrappers.slice(4);

        expect(daysOnHold.text()).to.equal('1 of 30');
        expect(documents.html()).to.include(`/reader/appeal/${taskWithNewDocs.externalAppealId}/documents`);
      }
    });
  });

  describe('On hold tab', () => {
    it('shows only on-hold tasks', () => {
      const task = amaTaskWith({
        id: '1',
        cssIdAssignee: 'BVALSPORER',
        placedOnHoldAt: moment().subtract(2, 'days'),
        onHoldDuration: 30
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
      store.dispatch(receiveNewDocuments({
        appealId: appealWithNewDocs.externalId,
        newDocuments: [{}]
      }));

      const wrapper = getWrapperColocatedTaskListView(store);

      wrapper.find('[aria-label="On hold (1) tab window"]').simulate('click');

      const cells = wrapper.find('td');

      expect(cells).to.have.length(6);
      const wrappers = [];

      for (let i = 0; i < cells.length; i++) {
        wrappers.push(cells.at(i));
      }
      const [caseDetails, columnTasks, types, docketNumber, daysOnHold, documents] = wrappers;

      expect(caseDetails.text()).to.include(appeal.veteranFullName);
      expect(caseDetails.text()).to.include(appeal.veteranFileNumber);
      expect(columnTasks.text()).to.include(CO_LOCATED_ADMIN_ACTIONS[task.label]);
      expect(types.text()).to.include(appeal.caseType);
      expect(docketNumber.text()).to.include(appeal.docketNumber);
      expect(daysOnHold.text()).to.equal('1 of 30');
      expect(documents.html()).to.include(`/reader/appeal/${task.externalAppealId}/documents`);
    });
  });
});
