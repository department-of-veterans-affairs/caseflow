import React from 'react';
import ReduxBase from 'app/components/ReduxBase';
import { reducer, generateInitialState } from 'app/intake';
import mockProps from './mockProps';
import RemoveIssueModal from './RemoveIssueModal';

const ReduxDecorator = (Story) => (
  <ReduxBase reducer={reducer} initialState={generateInitialState()}>
    <Story />
  </ReduxBase>
);

export default {
  component: RemoveIssueModal,
  decorators: [ReduxDecorator],
  title: 'Intake/Edit Issues/Remove Issue Modal',
};

export const Basic = () => {
  const { closeHandler, intakeData, removeIndex, removeIssue } = mockProps;

  return (
    <RemoveIssueModal
      closeHandler={closeHandler}
      intakeData={intakeData}
      removeIndex={removeIndex}
      removeIssue={removeIssue}
    />
  );
};

export const WithBenefitTypeProcessedInVBMS = () => {
  const { closeHandler, intakeData, removeIndex, removeIssue } = mockProps;

  return (
    <RemoveIssueModal
      closeHandler={closeHandler}
      intakeData={{ ...intakeData, benefitType: 'compensation' }}
      removeIndex={removeIndex}
      removeIssue={removeIssue}
    />
  );
};

export const WithVBMSBenefitTypeAndAppealFormType = () => {
  const { closeHandler, intakeData, removeIndex, removeIssue } = mockProps;

  return (
    <RemoveIssueModal
      closeHandler={closeHandler}
      intakeData={{ ...intakeData, benefitType: 'pension', formType: 'appeal' }}
      removeIndex={removeIndex}
      removeIssue={removeIssue}
    />
  );
};
