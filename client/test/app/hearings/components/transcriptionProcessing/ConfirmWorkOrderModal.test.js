import React from 'react';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import ConfirmWorkOrderModal
  from '../../../../../app/hearings/components/transcriptionProcessing/ConfirmWorkOrderModal';
import { BrowserRouter as Router } from 'react-router-dom';
import ApiUtil from '../../../../../app/util/ApiUtil';
import { axe } from 'jest-axe';
import COPY from "../../../../../COPY";

const onCancel = jest.fn();

const getSpy = jest.spyOn(ApiUtil, 'get');
const postSpy = jest.spyOn(ApiUtil, 'post');

const mockedHistoryValues = {
  selectedFiles: [{
    id: 1,
    selected: true
  }],
  workOrder: 'BVA-2024-0001',
  returnDateValue: '08/27/2024',
  contractor: {
    name: 'Real Contractor'
  }
};

const mockedFiles = [{
  docketNumber: 'H1234-5678',
  firstName: 'John',
  lastName: 'Smith',
  isAdvancedOnDocket: false,
  hearingDate: '06/04/2024',
  regionalOffice: 'Waco',
  judge: 'Judy',
  caseType: 'Original',
  appealType: 'AMA'
}];

const advanceOnDocketFiles = [{
  docketNumber: 'H1234-5678',
  firstName: 'John',
  lastName: 'Smith',
  isAdvancedOnDocket: true,
  hearingDate: '06/04/2024',
  regionalOffice: 'Waco',
  judge: 'Judy',
  caseType: 'Original',
  appealType: 'AMA'
}];

const setup = (selectedFiles, workOrder, returnDateValue, contractor) => {
  const history = { location: { state: { selectedFiles, workOrder, returnDateValue, contractor } } };

  return render(
    <Router>
      <ConfirmWorkOrderModal history={history} onCancel={onCancel} />
    </Router>
  );
};

describe('ConfirmWorkOrderModal', () => {
  it('Displays summary values correctly', () => {
    getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: mockedFiles })));
    setup(
      mockedHistoryValues.selectedFiles,
      mockedHistoryValues.workOrder,
      mockedHistoryValues.returnDateValue,
      mockedHistoryValues.contractor
    );
    expect(screen.getByText('BVA-2024-0001')).toBeInTheDocument();
    expect(screen.getByText('08/27/2024')).toBeInTheDocument();
    expect(screen.getByText('Real Contractor')).toBeInTheDocument();
  });

  it('does not display AOD types in table when not advanced on docket', async () => {
    getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: mockedFiles })));
    setup(
      mockedHistoryValues.selectedFiles,
      mockedHistoryValues.workOrder,
      mockedHistoryValues.returnDateValue,
      mockedHistoryValues.contractor
    );
    await waitFor(() => {
      expect(screen.getByText('Original')).toBeInTheDocument();
    });
  });

  it('displays AOD types in table when advanced on docket', async () => {
    getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: advanceOnDocketFiles })));
    setup(
      mockedHistoryValues.selectedFiles,
      mockedHistoryValues.workOrder,
      mockedHistoryValues.returnDateValue,
      mockedHistoryValues.contractor
    );
    await waitFor(() => {
      expect(screen.getByText('AOD')).toBeInTheDocument();
      expect(screen.getByText(', Original')).toBeInTheDocument();
    });
  });

  it('matches snapshot', async () => {
    getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: advanceOnDocketFiles })));
    const { container } = setup(
      mockedHistoryValues.selectedFiles,
      mockedHistoryValues.workOrder,
      mockedHistoryValues.returnDateValue,
      mockedHistoryValues.contractor
    );

    await waitFor(() => {
      expect(container).toMatchSnapshot();
    });
  });

  it('passes a11y testing', async () => {
    getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: advanceOnDocketFiles })));
    const { container } = setup(
      mockedHistoryValues.selectedFiles,
      mockedHistoryValues.workOrder,
      mockedHistoryValues.returnDateValue,
      mockedHistoryValues.contractor
    );
    const results = await axe(container);

    await waitFor(() => {
      expect(results).toHaveNoViolations();
    });
  });

  it('dispatches work order on button click', async () => {
    getSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({ body: advanceOnDocketFiles })));
    postSpy.mockImplementationOnce(() => new Promise((resolve) => resolve({})));

    setup(
      mockedHistoryValues.selectedFiles,
      mockedHistoryValues.workOrder,
      mockedHistoryValues.returnDateValue,
      mockedHistoryValues.contractor
    );

    await waitFor(() => {
      expect(screen.getByText('BVA-2024-0001')).toBeInTheDocument();
    });

    const dispatchButton = screen.getByText(COPY.TRANSCRIPTION_TABLE_DISPATCH_WORK_ORDER);

    fireEvent.click(dispatchButton);

    await waitFor(() => {
      expect(postSpy).toHaveBeenCalledWith('/hearings/transcription_packages/dispatch', expect.any(Object));
    });
  });
});
