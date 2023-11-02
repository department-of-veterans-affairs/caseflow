import React from 'react';
import { render } from '@testing-library/react';
import StaticLeversWrapper from './StaticLeversWrapper';
import { levers } from 'test/data/adminCaseDistributionLevers';

describe('StaticLeversWrapper', () => {
  it('renders inactive levers correctly', () => {
    const inactiveLevers = levers.filter((lever) => !lever.is_active);
    const { getByText } = render(
      <StaticLeversWrapper leverList={inactiveLevers.map((lever) => lever.item)}
        leverStore={{ getState: () => (
          { levers }) }} />
    );
    const inactiveLever1 = getByText(inactiveLevers[0].description);
    const inactiveLever2 = getByText(inactiveLevers[1].description);

    expect(inactiveLever1).toBeInTheDocument();
    expect(inactiveLever2).toBeInTheDocument();
  });
});
