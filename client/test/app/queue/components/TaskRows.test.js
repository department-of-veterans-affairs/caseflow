import React from 'react';
import { fireEvent, render, screen } from '@testing-library/react';
import TaskRows from '../../../../app/queue/components/TaskRows';
import COPY from '../../../../COPY';
import {
  completedReviewPackageTaskNoErrorsFoundData,
  cancelledReviewPackageTaskCancelTaskData
} from '../../../data/queue/taskLists/index';

test('renders ReviewTranscriptTask details correctly', () => {

  render(<TaskRows taskList={[completedReviewPackageTaskNoErrorsFoundData]} appeal={{}} />);

  // Check if assigned by and assignee names are rendered correctly
  expect(screen.getByText('L. Roth')).toBeInTheDocument();
  expect(screen.getByText('Board of Veterans\' Appeals')).toBeInTheDocument();

  // Check if task status is rendered
  expect(screen.getByText('Completed on')).toBeInTheDocument();

  // Check if the task instructions are rendered
  expect(screen.getByText('View task instructions')).toBeInTheDocument();
});

test('toggles task instructions visibility - Action: No Errors found', () => {

  render(<TaskRows taskList={[completedReviewPackageTaskNoErrorsFoundData]} appeal={{}} />);

  // Check if the instructions are initially hidden
  expect(screen.queryByText(COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS)).not.toBeInTheDocument();
  expect(screen.queryByText(COPY.UPLOAD_TRANSCRIPTION_VBMS_NO_ERRORS_ACTION_TYPE)).not.toBeInTheDocument();
  expect(screen.queryByText('These are some notes')).not.toBeInTheDocument();

  // Click the toggle button
  fireEvent.click(screen.getByText('View task instructions'));

  // Check if the instructions are now visible
  expect(screen.queryByText(COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS)).toBeInTheDocument();
  expect(screen.queryByText(COPY.UPLOAD_TRANSCRIPTION_VBMS_NO_ERRORS_ACTION_TYPE)).toBeInTheDocument();
  expect(screen.getByText('These are some notes')).toBeInTheDocument();
});

test('toggles task instructions visibility - Action: Cancel task', () => {

  render(<TaskRows taskList={[cancelledReviewPackageTaskCancelTaskData]} appeal={{}} />);

  // Check if the instructions are initially hidden
  expect(screen.queryByText(COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS)).not.toBeInTheDocument();
  expect(screen.queryByText(COPY.UPLOAD_TRANSCRIPTION_VBMS_CANCEL_ACTION_TYPE)).not.toBeInTheDocument();
  expect(screen.queryByText('these are cancellation notes')).not.toBeInTheDocument();

  // Click the toggle button
  fireEvent.click(screen.getByText('View task instructions'));

  // Check if the instructions are now visible
  expect(screen.getByText(COPY.REVIEW_TRANSCRIPT_TASK_DEFAULT_INSTRUCTIONS)).toBeInTheDocument();
  expect(screen.getByText(COPY.UPLOAD_TRANSCRIPTION_VBMS_CANCEL_ACTION_TYPE)).toBeInTheDocument();
  expect(screen.getByText('these are cancellation notes')).toBeInTheDocument();
});
