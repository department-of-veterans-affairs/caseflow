import React from "react";
import { render, screen } from '@testing-library/react';
import COPY from '../../../../COPY';
import IssueModificationList from 'app/intake/components/IssueModificationList';
import { mockedIssueModificationListProps, mockedModificationProps } from 'test/data/issueModificationListProps';
import { formatModificationIssueRequestsBySection } from 'app/intake/util/issues';

describe('IssueModificationList', () => {
  const setup = (testProps) => {
    render(
      <IssueModificationList
        {...testProps}
      />
    );
  };

  const issueModificationProps = formatModificationIssueRequestsBySection(mockedIssueModificationListProps);

  const modificationProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE,
    issuesArr: mockedModificationProps,
    lastSection: true
  };

  it('renders the section title for a "Modification" request type', () => {
    setup(modificationProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the information for "Modification" requests', () => {
    setup(modificationProps);

    expect(screen.getByText('CHAMPVA')).toBeInTheDocument();
  });
});
