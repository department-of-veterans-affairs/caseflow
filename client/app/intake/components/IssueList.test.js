import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import COPY from '../../../COPY';
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

  it('renders the "Add Decision Date" list action if an issue has no decision date', async () => {
    setup(mockedIssueListProps);

    const dropdowns = screen.getAllByRole('combobox', { name: 'Actions' });
    const dropdown = dropdowns[0];

    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

    expect(screen.getByText('Add decision date')).toBeInTheDocument();

  });

  it('clicking "Add Decision Date" list action will open the Add Decision Date Modal', async () => {
    setup(mockedIssueListProps);
    const dropdown = screen.getAllByText('Select action')[0];

    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

    expect(screen.getByText('Add decision date')).toBeInTheDocument();

    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });
    fireEvent.keyDown(dropdown, { key: 'Enter' });

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

  it('renders the "Edit decision date" list action if an issue originally has an editedDecisionDate', async () => {
    const propsWithEditedDecisionDate = {
      ...mockedIssueListProps,
    };

    propsWithEditedDecisionDate.issues[0].editedDecisionDate = '2023-07-20';

    setup(propsWithEditedDecisionDate);

    const dropdown = screen.getAllByText('Select action')[0];

    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

    expect(screen.getByText('Edit decision date')).toBeInTheDocument();
  });

  it('renders the request for issue updates dropdown actions', async () => {
    const propsWithRequestForIssueUpdates = {
      ...mockedIssueListProps,
      userCanRequestForIssueUpdates: true,
      showRequestIssueUpdateOptions: true
    };

    // having only one dropdown will be easier to query for
    propsWithRequestForIssueUpdates.issues.pop();

    setup(propsWithRequestForIssueUpdates);
    const dropdown = screen.getByText('Select action');

    fireEvent.keyDown(dropdown, { key: 'ArrowDown' });

    expect(screen.getByText('Request modification')).toBeInTheDocument();
    expect(screen.getByText('Request removal')).toBeInTheDocument();
    expect(screen.getByText('Request withdrawal')).toBeInTheDocument();
  });
});
