import React from 'react';
import { render, screen } from '@testing-library/react';
import COPY from '../../../COPY';
import userEvent from '@testing-library/user-event';
import IssuesList from 'app/intake/components/IssueList';
import { mockedIssueListProps } from './mockData/issueListProps';

describe('IssuesList', () => {
  const mockOnClickIssueAction = jest.fn();

  afterEach(() => {
    jest.clearAllMocks();
  });

  const setup = (testProps) =>
    render(
      <IssuesList
        {...testProps}
        onClickIssueAction={mockOnClickIssueAction}
      />
    );

  it('renders the "Add Decision Date" list action if an issue has no decision date', () => {
    setup(mockedIssueListProps);

    expect(screen.getByText('Add decision date')).toBeInTheDocument();

  });

  it('clicking "Add Decision Date" list action will open the Add Decision Date Modal', async () => {
    setup(mockedIssueListProps);
    const select = screen.getAllByText('Select action')[0].parentElement;

    await userEvent.selectOptions(select, ['Add decision date']);
    expect(mockOnClickIssueAction).toHaveBeenCalledWith(0, 'add_decision_date');

  });

  it('renders the no decision date banner if an issue has no decision date', () => {
    setup(mockedIssueListProps);

    expect(screen.getByText(COPY.VHA_NO_DECISION_DATE_BANNER)).toBeInTheDocument();
    expect(screen.getByText('Decision date: No date entered')).toBeInTheDocument();

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
