import { expect } from 'chai';
import { associateTasksWithAppeals, sortTasks } from '../../../app/queue/utils';

const serverData = {
  appeals: {
    data: [{
      id: '123',
      attributes: {
        external_id: '1',
        aod: true
      }
    }, {
      id: '234',
      attributes: {
        external_id: '2',
        type: 'Court Remand'
      }
    }, {
      id: '345',
      attributes: { external_id: '3' }
    }]
  },
  tasks: {
    data: [{
      id: '1',
      attributes: {
        appeal_id: '111',
        docket_date: '2017-12-28T17:18:20.412Z'
      }
    }, {
      id: '1',
      attributes: {
        appeal_id: '222',
        docket_date: '2016-10-07T03:15:27.580Z'
      }
    }, {
      id: '2',
      attributes: {
        appeal_id: '333',
        docket_date: '2015-10-13T06:47:34.155Z'
      }
    }, {
      id: '3',
      attributes: {
        appeal_id: '444',
        docket_date: '2016-03-01T04:15:51.123Z'
      }
    }]
  }
};

describe('QueueLoadingScreen', () => {
  it('associates queue decisions/appeals and tasks', () => {
    const { tasks: tasksWithAppeals } = associateTasksWithAppeals(serverData);

    expect(tasksWithAppeals).to.deep.equal({
      1: {
        id: '1',
        appealId: '1',
        attributes: {
          appeal_id: '222',
          docket_date: '2016-10-07T03:15:27.580Z'
        }
      },
      2: {
        id: '2',
        appealId: '2',
        attributes: {
          appeal_id: '333',
          docket_date: '2015-10-13T06:47:34.155Z'
        }
      },
      3: {
        id: '3',
        appealId: '3',
        attributes: {
          appeal_id: '444',
          docket_date: '2016-03-01T04:15:51.123Z'
        }
      }
    });
  });

  it('groups tasks by AOD/CAVC and sorts by docket date', () => {
    const { tasks, appeals } = associateTasksWithAppeals(serverData);

    const sortedTasks = sortTasks({
      tasks,
      appeals
    });

    expect(sortedTasks).to.deep.equal([{
      id: '2',
      appealId: '2',
      attributes: {
        appeal_id: '333',
        docket_date: '2015-10-13T06:47:34.155Z'
      }
    }, {
      id: '1',
      appealId: '1',
      attributes: {
        appeal_id: '222',
        docket_date: '2016-10-07T03:15:27.580Z'
      }
    }, {
      id: '3',
      appealId: '3',
      attributes: {
        appeal_id: '444',
        docket_date: '2016-03-01T04:15:51.123Z'
      }
    }]);
  });
});
