import { expect } from 'chai';
import { associateTasksWithAppeals, sortTasks } from '../../../app/queue/utils';

const serverData = {
  appeals: {
    data: [{
      id: '123',
      attributes: {
        vacols_id: '1',
        aod: true
      }
    }, {
      id: '234',
      attributes: {
        vacols_id: '2',
        type: 'Court Remand'
      }
    }, {
      id: '345',
      attributes: { vacols_id: '3' }
    }]
  },
  tasks: {
    data: [{
      id: '111',
      attributes: {
        appeal_id: '1',
        docket_date: '2017-12-28T17:18:20.412Z'
      }
    }, {
      id: '222',
      attributes: {
        appeal_id: '1',
        docket_date: '2016-10-07T03:15:27.580Z'
      }
    }, {
      id: '333',
      attributes: {
        appeal_id: '2',
        docket_date: '2015-10-13T06:47:34.155Z'
      }
    }, {
      id: '444',
      attributes: {
        appeal_id: '3',
        docket_date: '2016-03-01T04:15:51.123Z'
      }
    }]
  }
};

describe('QueueLoadingScreen', () => {
  it('associates queue decisions/appeals and tasks', () => {
    const { tasks: tasksWithAppeals } = associateTasksWithAppeals(serverData);

    expect(tasksWithAppeals).to.deep.equal({
      111: {
        id: '111',
        vacolsId: '1',
        attributes: {
          appeal_id: '1',
          docket_date: '2017-12-28T17:18:20.412Z'
        }
      },
      222: {
        id: '222',
        vacolsId: '1',
        attributes: {
          appeal_id: '1',
          docket_date: '2016-10-07T03:15:27.580Z'
        }
      },
      333: {
        id: '333',
        vacolsId: '2',
        attributes: {
          appeal_id: '2',
          docket_date: '2015-10-13T06:47:34.155Z'
        }
      },
      444: {
        id: '444',
        vacolsId: '3',
        attributes: {
          appeal_id: '3',
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
      id: '333',
      vacolsId: '2',
      attributes: {
        appeal_id: '2',
        docket_date: '2015-10-13T06:47:34.155Z'
      }
    }, {
      id: '222',
      vacolsId: '1',
      attributes: {
        appeal_id: '1',
        docket_date: '2016-10-07T03:15:27.580Z'
      }
    }, {
      id: '111',
      vacolsId: '1',
      attributes: {
        appeal_id: '1',
        docket_date: '2017-12-28T17:18:20.412Z'
      }
    }, {
      id: '444',
      vacolsId: '3',
      attributes: {
        appeal_id: '3',
        docket_date: '2016-03-01T04:15:51.123Z'
      }
    }]);
  });
});
