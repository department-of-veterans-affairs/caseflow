
import React from 'react';
import { render, waitFor, screen } from '@testing-library/react';
import COPY from '../../../../../COPY';
import ApiUtil from '../../../../../app/util/ApiUtil';
import { sprintf } from 'sprintf-js';

import {
  clickSubmissionButton,
  enterTextFieldOptions,
} from '../../../queue/components/modalUtils';

import { EditTotalHearingsModal } from
  '../../../../../app/hearings/components/transcriptionProcessing/EditTotalHearingsModal';

const onCancel = jest.fn().mockImplementation(() => {
  'Cancel';
});

const onConfirm = jest.fn().mockImplementation(() => {
  'Confirm';
});

const testContractor = {
  id: 1,
  directory: 'box_directory',
  email: 'test@va.gov',
  name: 'New Contractor',
  phone: 'phone-number',
  poc: 'person-of-contact',
  current_goal: 1
};

const renderEditTotalHearingsModal = () => {
  return render(
    <EditTotalHearingsModal onCancel={onCancel} onConfirm={onConfirm} transcriptionContractor={testContractor} />
  );
};

beforeEach(() => {
  jest.mock('../../../../../app/util/ApiUtil');
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('Add edit totalhearings form', () => {
  test('contains expected labels, fields and buttons', () => {
    const component = renderEditTotalHearingsModal();

    expect(component).toMatchSnapshot();
  });

  test('calls onCancel when cancel button is clicked', async () => {
    renderEditTotalHearingsModal();
    clickSubmissionButton(COPY.TRANSCRIPTION_SETTINGS_CANCEL);
    expect(onCancel).toHaveBeenCalled();
  });

  test('validates input to be greater than 0', async () => {
    testContractor.current_goal = 0;
    const component = renderEditTotalHearingsModal();

    expect(component).toMatchSnapshot();
  });

  test('validates input to be less than 1000', async () => {
    testContractor.current_goal = 1001;
    const component = renderEditTotalHearingsModal();

    expect(component).toMatchSnapshot();
  });

  test('validates input to not allow strings', async () => {
    testContractor.current_goal = 'invalid';
    const component = renderEditTotalHearingsModal();

    expect(component).toMatchSnapshot();
  });

  test('returns an alert on successful submit', async () => {
    ApiUtil.patch = jest.fn().mockResolvedValue({ body: { transcription_contractor: testContractor } });
    testContractor.current_goal = '';
    renderEditTotalHearingsModal();

    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_MODAL_INPUT_TEXT, '1000');
    clickSubmissionButton(COPY.MODAL_CONFIRM_BUTTON);

    expect(ApiUtil.patch).toHaveBeenCalledWith(
      '/hearings/find_by_contractor/1',
      { data: {
        transcription_contractor: {
          id: 1,
          directory: testContractor.directory,
          email: testContractor.email,
          name: testContractor.name,
          phone: testContractor.phone,
          poc: testContractor.poc,
          current_goal: '1000'
        }
      } }
    );

    await waitFor(() => expect(onConfirm).toHaveBeenCalledWith({
      alert: {
        message: sprintf(COPY.TRANSCRIPTION_SETTINGS_UPDATE_HEARINGS_GOAL_MESSAGE, testContractor.name),
        title: 'Success',
        type: 'success'
      },
      transcription_contractor: testContractor
    }));

  });

  test('displays an error from the server on failed form submit', async () => {
    ApiUtil.patch = jest.fn().mockRejectedValue();

    testContractor.current_goal = 1;
    renderEditTotalHearingsModal();

    clickSubmissionButton(COPY.MODAL_CONFIRM_BUTTON);

    await waitFor(() =>
      expect(screen.getByText(COPY.TRANSCRIPTION_SETTINGS_ERROR_MESSAGE)).toBeInTheDocument()
    );
  });

  test('dispays an error when submitting a goal under range', () => {
    testContractor.current_goal = 0;
    renderEditTotalHearingsModal();
    clickSubmissionButton(COPY.MODAL_CONFIRM_BUTTON);

    expect(screen.getByText(COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_VALIDATION)).toBeInTheDocument();
  });

  test('dispays an error when submitting a goal over range', () => {
    testContractor.current_goal = 1001;
    renderEditTotalHearingsModal();
    clickSubmissionButton(COPY.MODAL_CONFIRM_BUTTON);

    expect(screen.getByText(COPY.TRANSCRIPTION_SETTINGS_EDIT_TOTAL_HEARINGS_VALIDATION)).toBeInTheDocument();
  });
});

