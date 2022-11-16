import React from 'react';

import { render } from '@testing-library/react';

// Component to be tested
import CaseWorkerIndex from 'app/containers/CaseWorker/CaseWorkerIndex';

const setup = () => {
  return render(<CaseWorkerIndex currentUserHistoricalTasks={[]} />);
};

describe('CaseWorkerIndex', () => {
  it('renders correctly', () => {
    const { container } = setup();

    expect(container).toMatchSnapshot();
  });
});
