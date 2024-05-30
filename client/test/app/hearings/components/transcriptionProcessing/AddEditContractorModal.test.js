
import React from 'react';
import { render, waitFor, screen } from '@testing-library/react';
import COPY from '../../../../../COPY';
import ApiUtil from '../../../../../app/util/ApiUtil';

import {
  clickSubmissionButton,
  enterTextFieldOptions,
} from '../../../queue/components/modalUtils';

import { AddEditContractorModal } from
  '../../../../../app/hearings/components/transcriptionProcessing/AddEditContractorModal';

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

const renderAddContractorModal = () => {
  return render(
    <AddEditContractorModal onCancel={onCancel} onConfirm={onConfirm} title="Add contractor" />
  );
};

beforeEach(() => {
  jest.mock('../../../../../app/util/ApiUtil');
});

afterEach(() => {
  jest.clearAllMocks();
});

describe('Add contractor form', () => {
  test('contains expected labels, fields and buttons', () => {
    const component = renderAddContractorModal();

    expect(component).toMatchSnapshot();
  });

  test('requires all fields and displays errors on failed submit', () => {
    const component = renderAddContractorModal();

    clickSubmissionButton(COPY.TRANSCRIPTION_SETTINGS_ADD);
    expect(component).toMatchSnapshot();
  });

  test('calls onCancel when cancel button is clicked', async () => {
    renderAddContractorModal();
    clickSubmissionButton(COPY.TRANSCRIPTION_SETTINGS_CANCEL);
    expect(onCancel).toHaveBeenCalled();
  });

  test('returns an alert and a new contractor on successful submit', async () => {
    ApiUtil.post = jest.fn().mockResolvedValue({ body: { transcription_contractor: testContractor } });

    renderAddContractorModal();

    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_NAME, testContractor.name);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_DIRECTORY, testContractor.directory);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_POC, testContractor.poc);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_EMAIL, testContractor.email);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_PHONE, testContractor.phone);
    clickSubmissionButton(COPY.TRANSCRIPTION_SETTINGS_ADD);

    expect(ApiUtil.post).toHaveBeenCalledWith(
      '/hearings/find_by_contractor',
      { data: {
        transcription_contractor: {
          directory: testContractor.directory,
          email: testContractor.email,
          name: testContractor.name,
          phone: testContractor.phone,
          poc: testContractor.poc
        }
      } }
    );

    await waitFor(() => expect(onConfirm).toHaveBeenCalledWith({
      alert: {
        message: testContractor.name,
        title: `You have successfully created contractor #${ testContractor.id}`,
        type: 'success'
      },
      transcription_contractor: testContractor
    }));

  });

  test('displays an error from the server on failed form submit', async () => {
    ApiUtil.post = jest.fn().mockRejectedValue();

    renderAddContractorModal();

    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_NAME, testContractor.name);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_DIRECTORY, testContractor.directory);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_POC, testContractor.poc);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_EMAIL, testContractor.email);
    enterTextFieldOptions(COPY.TRANSCRIPTION_SETTINGS_LABEL_PHONE, testContractor.phone);
    clickSubmissionButton(COPY.TRANSCRIPTION_SETTINGS_ADD);

    await waitFor(() =>
      expect(screen.getByText(COPY.TRANSCRIPTION_SETTINGS_ERROR_MESSAGE)).toBeInTheDocument()
    );
  });
});
