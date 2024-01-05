import React from 'react';
import { render, screen } from '@testing-library/react';
import CaseflowDistributionContent from 'app/caseDistribution/components/CaseflowDistributionContent';
import { formattedHistory, formattedLevers } from 'test/data/formattedCaseDistributionData';
import { createStore } from 'redux';
import leversReducer from 'app/caseDistribution/reducers/Levers/leversReducer';

jest.mock('app/styles/caseDistribution/InteractableLevers.module.scss', () => '');
jest.mock('app/styles/caseDistribution/StaticLevers.module.scss', () => '');
jest.mock('app/styles/caseDistribution/LeverHistory.module.scss', () => '');
jest.mock('app/styles/caseDistribution/ExclusionTable.module.scss', () => '');

describe('CaseflowDistributionContent', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (testProps) =>
    render(
      <CaseflowDistributionContent {...testProps} />
    );

  it('renders the "CaseflowDistributionContent Component" with the data imported', () => {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(formattedLevers)),
      initial_levers: JSON.parse(JSON.stringify(formattedLevers))
    };

    const leverStore = createStore(leversReducer, preloadedState);

    let staticLevers = ['lever_1', 'lever_2'];
    let batchSizeLevers = ['lever_5', 'lever_6'];
    let affinityLevers = ['lever_9'];
    let docketLevers = ['lever_15'];
    let leversList = {
      staticLevers,
      affinityLevers,
      batchSizeLevers,
      docketLevers
    };

    let testProps = {
      levers: leversList,
      saveChanges: {},
      formattedHistory,
      leverStore,
      isAdmin: true
    };

    setup(testProps);

    expect(screen.getByText('Administration')).toBeInTheDocument();
    expect(screen.getByText('Maximum Direct Review Proportion')).toBeInTheDocument();
    expect(screen.getByText('Minimum Legacy Proportion')).toBeInTheDocument();
    expect(screen.getByText('Batch Size Per Attorney*')).toBeInTheDocument();
    expect(screen.getByText('AMA Hearing Case AOD Affinity Days')).toBeInTheDocument();
    expect(screen.getByText('Fri Jul 07 10:49:07 2023')).toBeInTheDocument();
  });

});
