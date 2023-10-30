import React from 'react';
import { render } from '@testing-library/react';
import StaticLeverWrapper from './StaticLeversWrapper';
import { levers } from 'test/data/adminCaseDistributionLevers';

describe('StaticLeverWrapper', () => {
  it('renders inactive levers correctly', () => {
    const inactiveLevers = levers.filter((lever) => !lever.is_active);
    const { getByTestId } = render(
      <StaticLeverWrapper levers={inactiveLevers} />
    );
    const inactiveLever1 = getByTestId('is_active');
    const inactiveLever2 = getByTestId('is_active');

    expect(inactiveLever1).toHaveTextContent(inactiveLevers[0].value);
    expect(inactiveLever2).toHaveTextContent(inactiveLevers[1].value);
  });
});
