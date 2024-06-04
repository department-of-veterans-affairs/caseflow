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
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';
import {
  createQueueReducer
} from 'test/app/queue/components/modalUtils';

describe('IssueModificationList', () => {
  const setup = (storeValues, testProps) => {
    const queueReducer = createQueueReducer(storeValues);
    const store = createStore(
      queueReducer,
      compose(applyMiddleware(thunk))
    );

    render(
      <Provider store={store}>
        <IssueModificationList
          {...testProps}
        />
      </Provider>
    );
  };

  const additionalProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE,
    issueModificationRequests: mockedAdditionRequestTypeProps,
    lastSection: true
  };

  const storeValues = { userIsVhaAdmin: true };

  const modificationProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE,
    issueModificationRequests: mockedModificationRequestProps,
    lastSection: true
  };

  const removalProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE,
    issueModificationRequests: mockedRemovalRequestTypeProps,
    lastSection: true
  };

  const withdrawalProps = {
    sectionTitle: COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE,
    issueModificationRequests: mockedWithdrawalRequestTypeProps,
    lastSection: true
  };

  it('renders the section title for a "Addition" request type', () => {
    setup(storeValues, additionalProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.ADDITION.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the section title for a "Modification" request type', () => {
    setup(storeValues, modificationProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.MODIFICATION.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the section title for a "Removal" request type', () => {
    setup(storeValues, removalProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.REMOVAL.SECTION_TITLE)).toBeInTheDocument();
  });

  it('renders the section title for a "Withdrawal" request type', () => {
    setup(storeValues, withdrawalProps);

    expect(screen.getByText(COPY.ISSUE_MODIFICATION_REQUESTS.WITHDRAWAL.SECTION_TITLE)).toBeInTheDocument();
  });
});
