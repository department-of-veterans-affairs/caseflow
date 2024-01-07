import React from 'react';
import { render } from '@testing-library/react';
import StaticLeverWrapper from 'app/caseDistribution/components/StaticLeversWrapper';
import { levers } from 'test/data/adminCaseDistributionLevers';
import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';
import { createStore } from 'redux';

const preloadedState = {
  levers: JSON.parse(JSON.stringify(levers)),
  backendLevers: JSON.parse(JSON.stringify(levers))
};
const leverStore = createStore(leversReducer, preloadedState);
const leverList = ['lever_3', 'lever_2', 'lever_7'];

jest.mock('app/styles/caseDistribution/StaticLevers.module.scss', () => '');
describe('StaticLeverWrapper', () => {
  it('renders inactive levers correctly', () => {
    const inactiveLevers = levers.filter((lever) => !lever.is_active);
    const { getByText } = render(<StaticLeverWrapper leverList={leverList} leverStore={leverStore} />);
    const inactiveLever = getByText(inactiveLevers[0].description);

    expect(inactiveLever).toBeInTheDocument();
  });
});
