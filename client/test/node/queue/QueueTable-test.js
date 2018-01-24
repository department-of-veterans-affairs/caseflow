import { expect } from 'chai';
import { associateTasksWithAppeals, sortTasks } from '../../../app/queue/utils';

describe('QueueTable', () => {
  it('groups tasks by AOD/CAVC and sorts by docket date', () => {
    const serverData = {
      appeals: {
        data: [{
          attributes: {
            vacols_id: '1',
            aod: true
          }
        }, {
          attributes: {
            vacols_id: '2',
            type: 'Court Remand'
          }
        }, {
          attributes: { vacols_id: '3' }
        }]
      },
      tasks: {
        data: [{
          attributes: {
            appeal_id: '1',
            docket_date: '2017-12-28T17:18:20.412Z'
          }
        }, {
          attributes: {
            appeal_id: '1',
            docket_date: '2016-10-07T03:15:27.580Z'
          }
        }, {
          attributes: {
            appeal_id: '2',
            docket_date: '2015-10-13T06:47:34.155Z'
          }
        }, {
          attributes: {
            appeal_id: '3',
            docket_date: '2016-03-01T04:15:51.123Z'
          }
        }]
      }
    };
    const { tasks } = associateTasksWithAppeals(serverData);
    const sortedTasks = sortTasks(tasks);

    expect(sortedTasks).to.deep.equal([{
      appeal: {
        attributes: {
          type: 'Court Remand',
          vacols_id: '2'
        }
      },
      attributes: {
        appeal_id: '2',
        docket_date: '2015-10-13T06:47:34.155Z'
      }
    }, {
      appeal: {
        attributes: {
          aod: true,
          vacols_id: '1'
        }
      },
      attributes: {
        appeal_id: '1',
        docket_date: '2016-10-07T03:15:27.580Z'
      }
    }, {
      appeal: {
        attributes: {
          vacols_id: '1',
          aod: true
        }
      },
      attributes: {
        appeal_id: '1',
        docket_date: '2017-12-28T17:18:20.412Z'
      }
    }, {
      appeal: {
        attributes: { vacols_id: '3' }
      },
      attributes: {
        appeal_id: '3',
        docket_date: '2016-03-01T04:15:51.123Z'
      }
    }]);
  });
});
