import { expect } from 'chai';
import { associateTasksWithAppeals } from '../../../app/queue/utils';

describe('QueueLoadingScreen', () => {
  it('associates queue decisions/appeals and tasks', () => {
    const appeals = {
      data: [
        { attributes: { vacols_id: '1' } },
        { attributes: { vacols_id: '2' } }
      ]
    };
    const tasks = {
      data: [
        { attributes: { appeal_id: '1' } },
        { attributes: { appeal_id: '1' } },
        { attributes: { appeal_id: '2' } }
      ]
    };
    const appealsWithTasks = associateTasksWithAppeals({
      appeals,
      tasks
    });

    expect(appealsWithTasks).to.deep.equal({
      appeals: [
        { attributes: { vacols_id: '1' } },
        { attributes: { vacols_id: '2' } }
      ],
      tasks: [{
          attributes: { appeal_id: '1' },
          appeal: {
            attributes: { vacols_id: '1' }
          }
        }, {
          attributes: { appeal_id: '1' },
          appeal: {
            attributes: { vacols_id: '1' }
          }
        }, {
          attributes: { appeal_id: '2' },
          appeal: {
            attributes: { vacols_id: '2' }
          }
        }]
    });
  });
});
