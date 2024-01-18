import React from 'react';
import { render, screen } from '@testing-library/react';
import CaseDistributionContent from 'app/caseDistribution/components/CaseDistributionContent';
import { formattedHistory, formattedLevers } from 'test/data/formattedCaseDistributionData';
import { createStore } from 'redux';
import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';

jest.mock('app/styles/caseDistribution/_interactable_levers.scss', () => '');
jest.mock('app/styles/caseDistribution/_static_levers.scss', () => '');
jest.mock('app/styles/caseDistribution/_lever_history.scss', () => '');
jest.mock('app/styles/caseDistribution/_exclusion_table.scss', () => '');

describe('CaseDistributionContent', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (testProps) =>
    render(
      <CaseDistributionContent {...testProps} />
    );

  it('renders the "CaseDistributionContent Component" with the data imported', () => {
    const preloadedState = {
      levers: JSON.parse(JSON.stringify(formattedLevers)),
      backendLevers: JSON.parse(JSON.stringify(formattedLevers))
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
