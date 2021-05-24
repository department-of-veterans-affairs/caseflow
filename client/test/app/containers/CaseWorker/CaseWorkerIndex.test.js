import React from 'react';

import { mount } from 'enzyme';

// Component to be tested
import CaseWorkerIndex from 'app/containers/CaseWorker/CaseWorkerIndex';

const setup = () => {
  return mount(<CaseWorkerIndex currentUserHistoricalTasks={[]}/>)
};

describe('CaseWorkerIndex', () => {
  it('renders correctly', async () => {
    const caseWorkerIndex = setup();

    expect(caseWorkerIndex).toMatchSnapshot();
  });
});