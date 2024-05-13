import React from 'react';
import { render, screen } from '@testing-library/react';
import COPY from '../../../../COPY';
import IssueModificationList from 'app/intake/components/IssueModificationList';
import {
  mockedModificationRequestProps,
  mockedAdditionRequestTypeProps,
  mockedRemovalRequestTypeProps,
  mockedWithdrawalRequestTypeProps
} from 'test/data/issueModificationListProps';

describe('IssueModificationList', () => {
  const setup = (testProps) => {
    render(
      <IssueModificationList
        {...testProps}
      />
    );
  };

  const additionalProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE,
    issuesArr: mockedAdditionRequestTypeProps,
    lastSection: true
  };

  const modificationProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE,
    issuesArr: mockedModificationRequestProps,
    lastSection: true
  };

  const removalProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE,
    issuesArr: mockedRemovalRequestTypeProps,
    lastSection: true
  };

  const withdrawalProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE,
    issuesArr: mockedWithdrawalRequestTypeProps,
    lastSection: true
  };

  it('renders the section title for a "Addition" request type', () => {
    setup(additionalProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the section title for a "Modification" request type', () => {
    setup(modificationProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the section title for a "Removal" request type', () => {
    setup(removalProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the section title for a "Withdrawal" request type', () => {
    setup(withdrawalProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE)).toBeInTheDocument();
  });
});
