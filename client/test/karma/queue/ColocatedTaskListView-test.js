import React from 'react';
import { expect } from 'chai';
import { mount } from 'enzyme';
import { Provider } from 'react-redux';
import ColocatedTaskListView from '../../../app/queue/ColocatedTaskListView';
import { createStore, applyMiddleware } from 'redux';
import moment from 'moment';
import pluralize from 'pluralize';
import thunk from 'redux-thunk';
import rootReducer from '../../../app/queue/reducers';
import { errorFetchingDocumentCount, setAppealDocCount, setQueueConfig }
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

  afterEach(() => {
    if (wrapperColocatedTaskListView) {
      wrapperColocatedTaskListView.unmount();
      wrapperColocatedTaskListView = null;
    }
  });

  const getAmaTaskTemplate = () => ({
    id: '1437',
    type: 'task_column',
    attributes: {
      docket_name: 'direct_review',
      docket_number: '200603-70',
      external_appeal_id: 'fe583ee4-6f58-41a6-b8c5-09bfdc987c75',
      paper_case: null,
      veteran_full_name: 'Bob Smith',
      veteran_file_number: '760362568',
      started_at: null,
      issue_count: null,
      aod: false,
      case_type: 'Original',
      label: 'Stayed appeal',
      placed_on_hold_at: null,
      on_hold_duration: null,
      status: null,
      assigned_at: moment().subtract(47, 'hours').
        format(),
      closest_regional_office: null,
      assigned_to: {
        css_id: null,
        is_organization: null,
        name: null,
        type: null,
        id: null
      },
      assigned_by: {
        first_name: 'Steve',
        last_name: 'Casper',
        css_id: 'BVASCASPER1',
        pg_id: 1
      },
      power_of_attorney_name: null,
      suggested_hearing_location: null,
      assignee_name: null,
      is_legacy: null,
      type: null,
      appeal_id: null,
      created_at: null,
      closed_at: null,
      instructions: null,
      appeal_type: null,
      timeline_title: null,
      hide_from_queue_table_view: null,
      hide_from_case_timeline: null,
      hide_from_task_snapshot: null,
      docket_range_date: null,
      external_hearing_id: null,
      available_hearing_locations: null,
      previous_task: {
        assigned_at: null
      },
      document_id: null,
      decision_prepared_by: {
        first_name: null,
        last_name: null
      },
      available_actions: [],
      cancelled_by: {
        css_id: null
      }
    }
  });

  const amaTaskWith = ({ ...rest }) => {
    const amaTaskTemplate = getAmaTaskTemplate();

    return ({
      ...amaTaskTemplate,
      ...rest,
      attributes: {
        ...amaTaskTemplate.attributes,
        ...rest.attributes
      }
    });
  };

  const daysOnHold = 31;

  const taskNewAssigned = amaTaskWith({ id: '1' });

  const completedHoldTask = amaTaskWith({
    id: '6',
    attributes: {
      assigned_at: moment().subtract(daysOnHold + 0.5, 'days').
        format(),
      placed_on_hold_at: moment().subtract(daysOnHold, 'days').
        format(),
      on_hold_duration: daysOnHold - 1
    }
  });

  const taskOnHold = amaTaskWith({
    id: '1',
    attributes: {
      placed_on_hold_at: moment().subtract(2, 'days').
        format(),
      on_hold_duration: daysOnHold,
      status: 'on_hold'
    }
  });

  const noOnHoldDurationTask = amaTaskWith({
    id: '7',
    attributes: {
      assigned_at: moment().subtract(daysOnHold + 0.5, 'days').
        format(),
      placed_on_hold_at: moment().subtract(daysOnHold, 'days').
        format(),
      status: 'on_hold'
    }
  });

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const queueConfig = {
    active_tab: 'assigned',
    table_title: 'Your cases',
    tabs: [
      {
        allow_bulk_assign: false,
        columns: [
          {
            filter_options: [],
            filterable: false,
            name: 'badgesColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'detailsColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'taskColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'typeColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'docketNumberColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'daysWaitingColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'readerLinkColumn'
          }
        ],
        description: 'Cases assigned to you:',
        label: 'Assigned (%d)',
        name: 'assigned_person',
        task_page_count: 1,
        task_page_endpoint_base_path: 'task_pages?tab=assigned_person',
        tasks: [
          taskNewAssigned,
          completedHoldTask
        ],
        total_task_count: 2
      },
      {
        allow_bulk_assign: false,
        columns: [
          {
            filter_options: [],
            filterable: false,
            name: 'badgesColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'detailsColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'taskColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'typeColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'docketNumberColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'daysOnHoldColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'readerLinkWithNewDocIconColumn'
          }
        ],
        description: 'Cases on hold (will return to \"Assigned\" tab when hold is completed):',
        label: 'On hold (%d)',
        name: 'on_hold_person',
        task_page_count: 1,
        task_page_endpoint_base_path: 'task_pages?tab=on_hold_person',
        tasks: [
          taskOnHold,
          noOnHoldDurationTask
        ],
        total_task_count: 2
      },
      {
        allow_bulk_assign: false,
        columns: [
          {
            filter_options: [],
            filterable: false,
            name: 'badgesColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'detailsColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'taskColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'typeColumn'
          },
          {
            filter_options: [],
            filterable: true,
            name: 'docketNumberColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'completedDateColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'completedToNameColumn'
          },
          {
            filter_options: [],
            filterable: false,
            name: 'readerLinkColumn'
          }
        ],
        description: 'Cases completed (last two weeks):',
        label: 'Completed',
        name: 'completed_person',
        task_page_count: 0,
        task_page_endpoint_base_path: 'task_pages?tab=completed_person',
        tasks: [],
        total_task_count: 0
      }
    ],
    tasks_per_page: 15,
    use_task_pages_api: false
  };

  /* eslint-disable no-unused-expressions */
  describe('Assigned tab', () => {
    it('shows only new tasks and tasks with a completed hold', () => {
      const task = taskNewAssigned.attributes;

      const store = getStore();

      store.dispatch(setUserCssId(task.assigned_to.css_id));
      store.dispatch(setQueueConfig(queueConfig));

      const wrapper = getWrapperColocatedTaskListView(store);

      const cells = wrapper.find('td');

      expect(cells).to.have.length(14);
      const wrappers = [];

      for (let i = 0; i < cells.length / 2; i++) {
        wrappers.push(cells.at(i));
      }
      const [hearings, caseDetails, columnTasks, types, docketNumber, daysWaiting, documents] = wrappers;

      expect(hearings.text()).to.include('');
      expect(caseDetails.text()).to.include(task.veteran_full_name);
      expect(caseDetails.text()).to.include(task.veteran_file_number);
      expect(columnTasks.text()).to.include(task.label);
      expect(types.text()).to.include(task.case_type);
      expect(docketNumber.text()).to.include(task.docket_number);
      expect(daysWaiting.text()).to.equal('1 day');
      expect(documents.html()).to.include(`/reader/appeal/${task.external_appeal_id}/documents`);
      expect(documents.text()).to.include('Loading number of docs...');

      store.dispatch(errorFetchingDocumentCount(task.external_appeal_id));
      expect(wrapper.find('td').at(6).
        text()).to.include('Failed to Load');

      store.dispatch(setAppealDocCount(task.external_appeal_id, 5));
      expect(wrapper.find('td').at(6).
        text()).to.include('5');

      const onHoldDaysWaiting = cells.at(12);

      expect(onHoldDaysWaiting.text()).to.equal(`${daysOnHold.toString()} ${pluralize('day', daysOnHold)}`);
      expect(onHoldDaysWaiting.find('.cf-red-text').length).to.eq(1);
      expect(onHoldDaysWaiting.find('.cf-continuous-progress-bar-warning').length).to.eq(1);
    });
  });

  describe('On hold tab', () => {
    it('shows only on-hold tasks', () => {
      const task = taskOnHold.attributes;

      const store = getStore();

      store.dispatch(setUserCssId(task.assigned_to.css_id));
      store.dispatch(setQueueConfig(queueConfig));

      const wrapper = getWrapperColocatedTaskListView(store);

      wrapper.find('[aria-label="On hold (2) tab window"]').simulate('click');

      const cells = wrapper.find('td');

      expect(cells).to.have.length(14);
      const wrappers = [];

      for (let i = 0; i < cells.length / 2; i++) {
        wrappers.push(cells.at(i));
      }
      const [hearings, caseDetails, columnTasks, types, docketNumber, numberDaysOnHold, documents] = wrappers;

      expect(hearings.text()).to.include('');
      expect(caseDetails.text()).to.include(task.veteran_full_name);
      expect(caseDetails.text()).to.include(task.veteran_file_number);
      expect(columnTasks.text()).to.include(task.label);
      expect(types.text()).to.include(task.case_type);
      expect(docketNumber.text()).to.include(task.docket_number);
      expect(numberDaysOnHold.text()).to.equal(`1 of ${daysOnHold.toString()}`);
      expect(numberDaysOnHold.find('.cf-continuous-progress-bar').length).to.eq(1);
      expect(documents.html()).to.include(`/reader/appeal/${task.external_appeal_id}/documents`);

      const onHoldDaysWaiting = cells.at(12);

      expect(onHoldDaysWaiting.text()).to.equal((daysOnHold - 1).toString());
      expect(onHoldDaysWaiting.find('.cf-red-text').length).to.eq(0);
      expect(onHoldDaysWaiting.find('.cf-continuous-progress-bar-warning').length).to.eq(0);
    });
  });
});
/* eslint-enable no-unused-expressions */
