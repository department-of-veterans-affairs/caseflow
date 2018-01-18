import { expect } from 'chai';
import { getRowObjects } from '../../../app/queue/QueueTable';

describe('QueueTable', () => {
  it('renders queue tasks and appeals', () => {
    const tasks = [];
    const appeals = [];
    const rowObjects = getRowObjects({ appeals, tasks });

    expect(rowObjects).to.deep.equal([]);
  });
});
