import React from 'react';
import { render, screen } from '@testing-library/react';
import { ConfirmPendingRequestIssueModal } from 'app/intake/components/ConfirmPendingRequestIssueModal';
import {
  mockedModificationRequestProps,
} from 'test/data/issueModificationListProps';
import { useSelector } from 'react-redux';

jest.mock('react-redux', () => ({
  ...jest.requireActual('react-redux'),
  useSelector: jest.fn(),
  useDispatch: jest.fn()
}));

describe('ConfirmPendingRequestIssueModal', () => {
  const setup = (testProps) => {
    render(
      <ConfirmPendingRequestIssueModal
        {...testProps}
      />
    );
  };

  const propsForConfirmModification = {
    pendingIssueModificationRequest: mockedModificationRequestProps[1],
    toggleConfirmPendingRequestIssueModal: jest.fn(),
    addIssue: jest.fn(),
    removeIssue: jest.fn(),
    removeFromPendingReviewSection: jest.fn()
  };

  it('renders the confirm pending issue modal for modification', () => {
    // The modal uses a useSelector hook on load so we will mock its return value since we are not connecting to redux.
    useSelector.mockReturnValueOnce(mockedModificationRequestProps[1]);
    setup(propsForConfirmModification);

    expect(screen.getByText(/Confirm changes/)).toBeInTheDocument();

    // Original Request Issue
    expect(screen.getByText(/Delete original issue/)).toBeInTheDocument();
    expect(screen.getByText(/Beneficiary Travel/)).toBeInTheDocument();
    expect(screen.getAllByText(/09\/23\/2023/)[0]).toBeInTheDocument();
    expect(screen.getByText(/Stuff/)).toBeInTheDocument();

    // New Pending Issue Accepted
    expect(screen.getByText(/Create new issue/)).toBeInTheDocument();
    expect(screen.getByText(/CHAMPVA/)).toBeInTheDocument();
    expect(screen.getByText(/Money for CHAMPVA/)).toBeInTheDocument();
    expect(screen.getByText(/01\/30\/2024/)).toBeInTheDocument();
  });
});
