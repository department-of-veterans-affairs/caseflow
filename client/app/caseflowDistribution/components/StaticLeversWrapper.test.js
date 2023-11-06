import React from 'react';
import { render } from '@testing-library/react';
import StaticLeverWrapper from './StaticLeversWrapper';
import { levers } from 'test/data/adminCaseDistributionLevers';

describe('StaticLeverWrapper', () => {
  it('renders inactive levers correctly', () => {
    const inactiveLevers = levers.filter((lever) => !lever.is_active);
    const { getByText } = render(<StaticLeverWrapper />);
    const inactiveLever = getByText(inactiveLevers[0].description);

    expect(inactiveLever).toBeInTheDocument();
  });
});
