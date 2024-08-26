import React from 'react';
import { render, screen } from '@testing-library/react';
import { CancelPendingRequestIssueModal } from 'app/intake/components/CancelPendingRequestIssueModal';
import {
  mockedModificationRequestProps,
  mockedAdditionRequestTypeProps,
  mockedRemovalRequestTypeProps,
  mockedWithdrawalRequestTypeProps
} from 'test/data/issueModificationListProps';

describe('CancelPendingRequestIssueModal', () => {
  const setup = (testProps) => {
    render(
      <CancelPendingRequestIssueModal
        {...testProps}
      />
    );
  };

  const propsForCancelModification = {
    pendingIssueModificationRequest: mockedModificationRequestProps[1],
    onCancel: jest.fn(),
    removeFromPendingReviewSection: jest.fn(),
    toggleCancelPendingRequestIssueModal: jest.fn()
  };

  const propsForCancelAddition = {
    pendingIssueModificationRequest: mockedAdditionRequestTypeProps[0],
    onCancel: jest.fn(),
    removeFromPendingReviewSection: jest.fn(),
    toggleCancelPendingRequestIssueModal: jest.fn()
  };

  const propsForCancelRemoval = {
    pendingIssueModificationRequest: mockedRemovalRequestTypeProps[0],
    onCancel: jest.fn(),
    removeFromPendingReviewSection: jest.fn(),
    toggleCancelPendingRequestIssueModal: jest.fn()
  };

  const propsForCancelWithdrawal = {
    pendingIssueModificationRequest: mockedWithdrawalRequestTypeProps[0],
    onCancel: jest.fn(),
    removeFromPendingReviewSection: jest.fn(),
    toggleCancelPendingRequestIssueModal: jest.fn()
  };

  it('renders the cancel pending issue modal for modification', () => {
    setup(propsForCancelModification);

    expect(screen.getByText('Cancel pending request')).toBeInTheDocument();

    // Current Requested Issue Information
    expect(screen.getByText(/Beneficiary Travel/)).toBeInTheDocument();
    expect(screen.getAllByText(/09\/23\/2023/)[0]).toBeInTheDocument();
    expect(screen.getByText(/Stuff/)).toBeInTheDocument();

    // Pending Requested Issue Modification Information
    expect(screen.getByText(/CHAMPVA/)).toBeInTheDocument();
    expect(screen.getByText(/Money for CHAMPVA/)).toBeInTheDocument();
    expect(screen.getByText(/01\/30\/2024/)).toBeInTheDocument();
    expect(screen.getByText(/Reasoning for requested Modification to this issue./)).toBeInTheDocument();

  });

  it('renders the cancel pending issue modal for addition', () => {
    setup(propsForCancelAddition);

    // Pending New Request Issue Information
    expect(screen.getByText('Cancel pending request')).toBeInTheDocument();
    expect(screen.getByText(/Beneficiary Travel/)).toBeInTheDocument();
    expect(screen.getByText(/01\/30\/2024/)).toBeInTheDocument();
    expect(screen.getByText(/Money for Travel/)).toBeInTheDocument();
    expect(screen.getByText(/Reasoning for requested Modification to this issue./)).toBeInTheDocument();

  });

  it('renders the cancel pending issue modal for removal', () => {
    setup(propsForCancelRemoval);

    // Current Issue Removal Information
    expect(screen.getByText('Cancel pending request')).toBeInTheDocument();
    expect(screen.getByText(/Caregiver | Eligibility/)).toBeInTheDocument();
    expect(screen.getByText(/01\/30\/2024/)).toBeInTheDocument();
    expect(screen.getByText(/Money for Care/)).toBeInTheDocument();
    expect(screen.getByText(/Reasoning for requested Modification to this issue./)).toBeInTheDocument();

  });

  it('renders the cancel pending issue modal for withdrawal', () => {
    setup(propsForCancelWithdrawal);

    // Pending Current Issue Withdrawal Information
    expect(screen.getByText('Cancel pending request')).toBeInTheDocument();
    expect(screen.getByText(/Caregiver | Eligibility/)).toBeInTheDocument();
    expect(screen.getByText(/11\/30\/2023/)).toBeInTheDocument();
    expect(screen.getByText(/Money for Care/)).toBeInTheDocument();
    expect(screen.getByText(/Reasoning for requested Modification to this issue./)).toBeInTheDocument();
  });
});
