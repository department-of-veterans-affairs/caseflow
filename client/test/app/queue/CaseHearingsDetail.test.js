import React from 'react';
import { render, screen } from '@testing-library/react';
import { axe } from 'jest-axe';
import { within } from '@testing-library/dom'

import { generateAmaTask } from 'test/data/tasks';
import { openHearingAppeal, amaAppealHearingData } from 'test/data/appeals';
import { queueWrapper } from '../../data/stores/queueStore';
import COPY from '../../../COPY.json'
import CaseHearingsDetail from 'app/queue/CaseHearingsDetail';

describe('CaseHearingDetail', () => {
  const hearingTask = generateAmaTask({
    taskId: '3',
    type: 'HearingTask',
    status: 'on_hold'
  })
  const defaultProps = {
    hearingTasks: [hearingTask],
    appeal: openHearingAppeal,
    title: 'Hearings'
  }

  it('renders correctly', () => {
    const { container } = render(
      <CaseHearingsDetail {...defaultProps} />, { wrapper: queueWrapper }
    );

    expect(container).toMatchSnapshot();
  });

  it('passes a11y testing', async () => {
    const { container } = render(
      <CaseHearingsDetail {...defaultProps} />,
      { wrapper: queueWrapper }
    );

    const results = await axe(container);

    expect(results).toHaveNoViolations();
  });

  it('displays Unscheduled Hearings', async () => {
    const notes = 'Prefilled notes'
    const hearingTaskWithNotesData = {
      ...hearingTask,
      unscheduledHearingNotes: {
        updatedAt: '2020-09-08T10:03:49.210-04:00',
        updatedByCssId: 'BVASYELLOW',
        notes: notes
      }
    }
    render(
      <CaseHearingsDetail {...defaultProps} hearingTasks={[hearingTaskWithNotesData]} />,
      { wrapper: queueWrapper }
    );

    expect(screen.getByText(`${COPY.UNSCHEDULED_HEARING_TITLE}:`)).toBeInTheDocument()
    expect(screen.getByText(`${COPY.UNSCHEDULED_HEARING_TITLE}:`)).toBeInTheDocument()

    expect(screen.getByText('Notes:')).toBeInTheDocument()
    expect(screen.getByText('Edit')).toBeInTheDocument()
    expect(screen.getByText(notes)).toBeInTheDocument()
    expect(screen.getByText('Last updated by BVASYELLOW on 09/08/2020'))
      .toBeInTheDocument()
  })

  it('displays both Unscheduled Hearing and Scheduled Hearing', () => {
    render(
      <CaseHearingsDetail {...defaultProps} appeal={openHearingAppeal} />,
      { wrapper: queueWrapper }
    );

    expect(screen.getByText(`${COPY.UNSCHEDULED_HEARING_TITLE}:`)).toBeInTheDocument()
    expect(screen.getByText('Hearing:')).toBeInTheDocument()
  })

  it('displays multiple hearings in correct order', () => {
    const appealWithTwoHearings = {
      ...openHearingAppeal,
      hearings: [
        openHearingAppeal.hearings[0],
        {
          ...amaAppealHearingData,
          date: '2020-10-07T03:30:00.000-04:00',
          createdAt: '2020-09-07T03:30:00.000-04:00',
          externalId: 'b5790483-f10f-4d52-b82a-2ae67a5ad4a8'
        }
      ]
    }

    const c = render(
      <CaseHearingsDetail {...defaultProps} appeal={appealWithTwoHearings} />,
      { wrapper: queueWrapper }
    );

    expect(
      screen.getByText(`${COPY.CASE_DETAILS_HEARING_LIST_LABEL}:`)
    ).toBeInTheDocument()

    const hearingOne = screen.getByText('Hearing 2:').closest('div')
    expect(within(hearingOne).getByText('10/7/20')).toBeInTheDocument()
    const hearingTwo = screen.getByText('Hearing 1:').closest('div')
    expect(within(hearingTwo).getByText('8/7/20')).toBeInTheDocument()
  })

  it('displays two Unscheduled hearing if there are two Hearing Tasks', () => {
    render(
      <CaseHearingsDetail
        {...defaultProps}
        hearingTasks={[hearingTask, generateAmaTask({...hearingTask, taskId: '4'})]} />,
      { wrapper: queueWrapper }
    );

    expect(screen.getByText(`${COPY.UNSCHEDULED_HEARING_TITLE} 1:`)).toBeInTheDocument()
    expect(screen.getByText(`${COPY.UNSCHEDULED_HEARING_TITLE} 2:`)).toBeInTheDocument()
  })
})
