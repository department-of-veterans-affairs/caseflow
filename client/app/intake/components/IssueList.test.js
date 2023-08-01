import React from 'react';
import { render, screen } from '@testing-library/react';
import COPY from '../../../COPY';
import IssuesList from 'app/intake/components/IssueList';
import { mockedIssueListProps } from './mockData/issueListProps';

describe('IssuesList', () => {
  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (testProps) =>
    render(
      <IssuesList
        {...testProps}
      />
    );

  it('renders the no decision date banner if an issue has no decision date', () => {
    setup(mockedIssueListProps);

    expect(screen.getByText(COPY.VHA_NO_DECISION_DATE_BANNER)).toBeInTheDocument();

  });

  it('does not render the no decision date banner if an issue has a decision date', () => {
    const propsWithDecisionDates = {
      ...mockedIssueListProps,
    };

    // Alter the first issue to have a decision date.
    propsWithDecisionDates.issues[0].date = '2023-07-20';

    setup(mockedIssueListProps);

    expect(screen.queryByText(COPY.VHA_NO_DECISION_DATE_BANNER)).not.toBeInTheDocument();

  });
});
