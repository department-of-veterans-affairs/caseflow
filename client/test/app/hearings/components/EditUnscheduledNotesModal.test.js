import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';

import { generateAmaTask } from 'test/data/tasks';
import { amaAppeal } from 'test/data/appeals';

import { EditUnscheduledNotesModal } from 'app/hearings/components/EditUnscheduledNotesModal';

describe('EditUnscheduledNotesModal', () => {
  const onCancel = jest.fn();
  const hearingTask = generateAmaTask({
    uniqueId: '3',
    type: 'HearingTask',
    status: 'on_hold'
  })
  const defaultProps = {
    task: hearingTask,
    appeal: amaAppeal,
    onCancel: onCancel
  }

  it('renders correctly', () => {
    const { container } = render(<EditUnscheduledNotesModal {...defaultProps} />);

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(<EditUnscheduledNotesModal {...defaultProps} />);

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('displays pre filled data', () => {
    const maxCharLimit = 1000
    const notes = "Pre filled notes"
    const hearingTaskWithNotesData = {
      ...hearingTask,
      unscheduledHearingNotes: {
        updatedAt: '2020-09-08T10:03:49.210-04:00',
        updatedByCssId: 'BVASYELLOW',
        notes: notes
      }
    }
    render(
      <EditUnscheduledNotesModal {...defaultProps} task={hearingTaskWithNotesData}/>
    );

    expect(screen.getByLabelText('Notes')).toBeInTheDocument()
    expect(screen.getByText(notes)).toBeInTheDocument()
    const charLimitMessage = `${maxCharLimit - notes.length} characters left`
    expect(screen.getByText(charLimitMessage)).toBeInTheDocument()
    expect(screen.getByText('Last updated by BVASYELLOW on 09/08/2020'))
      .toBeInTheDocument()
  })
})
