import { expect } from 'chai';
import { getRowObjects } from '../../../app/queue/QueueTable';

describe('QueueTable', () => {
  it('renders queue tasks and appeals', () => {
    const appeals = [
      { attributes: { vacols_id: '1' } },
      { attributes: { vacols_id: '2' } }
    ];
    const tasks = [
      { attributes: { appeal_id: '1' } },
      { attributes: { appeal_id: '1' } },
      { attributes: { appeal_id: '2' } }
    ];
    const rowObjects = getRowObjects({
      appeals,
      tasks
    });

    expect(rowObjects).to.deep.equal([
      {
        attributes: { vacols_id: '1' },
        tasks: [
          { attributes: { appeal_id: '1' } },
          { attributes: { appeal_id: '1' } }
        ]
      }, {
        attributes: { vacols_id: '2' },
        tasks: [
          { attributes: { appeal_id: '2' } }
        ]
      }
    ]);
  });
});
