import { createSelector } from 'reselect';

const selectPendingIssueModificationRequests = (state) => state.pendingIssueModificationRequests;

export const getOpenPendingIssueModificationRequests = createSelector(
  [selectPendingIssueModificationRequests],
  (pendingIssueModificationRequests) =>
    pendingIssueModificationRequests.filter((request) => request.status === 'assigned')
);
