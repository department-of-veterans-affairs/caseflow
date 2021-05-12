import { axe } from 'jest-axe';
import React from 'react';

import { SubstituteAppellantReview } from 'app/queue/substituteAppellant/review/SubstituteAppellantReview';
import { queueWrapper as Wrapper } from '../../../../test/data/stores/queueStore';
import { MemoryRouter } from 'react-router';
import { render } from '@testing-library/react';
import { sampleEvidenceSubmissionTasks } from 'test/data/queue/substituteAppellant/tasks';

describe('SubstituteAppellantReview', () => {
  const onBack = jest.fn();
  const onCancel = jest.fn();
  const onSubmit = jest.fn();
  const sampleTasks = sampleEvidenceSubmissionTasks();
  const selectedTaskIds = sampleTasks.slice(2).map((task) => task.taskId);

  const defaults = {
    selectedTasks: sampleTasks,
    existingValues: { substitutionDate: '2021-03-25',
      participantId: 'particip-id',
      taskIds: selectedTaskIds },
    evidenceSubmissionEndDate: new Date('2021-05-30'),
    onBack,
    onCancel,
    onSubmit
  };

  const storeArgs = {
    substituteAppellant: {
      relationships: [
        { value: 'CLAIMANT_WITH_PVA_AS_VSO',
          fullName: 'Bob Vance',
          relationshipType: 'Spouse',
          displayText: 'Bob Vance, Spouse',
        },
        { value: '"1129318238"',
          fullName: 'Cathy Smith',
          relationshipType: 'Child',
          displayText: 'Cathy Smith, Child',
        },
      ],
    },
  };

  const setup = (props) =>
    render(
      <MemoryRouter>
        <Wrapper {...storeArgs}>
          <SubstituteAppellantReview {...defaults} {...props} />
        </Wrapper>
      </MemoryRouter>
    );

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('passes a11y testing', async () => {
    const { container } = setup();

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });
});
