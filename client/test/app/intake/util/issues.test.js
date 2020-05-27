import { formatAddedIssues } from 'app/intake/util/issues';

const addedIssues = [
  {
    id: '2',
    decisionIssueId: null,
    description: 'PTSD denied',
    decisionDate: '2020-05-07',
    ineligibleReason: null,
    ineligibleDueToId: null,
    decisionReviewTitle: 'Appeal',
    contentionText: 'PTSD denied',
    vacolsId: null,
    vacolsSequenceId: null,
    vacolsIssue: null,
    endProductCleared: null,
    endProductCode: null,
    withdrawalDate: null,
    editable: true,
    examRequested: null,
    isUnidentified: null,
    notes: null,
    category: null,
    index: '1',
    isRating: true,
    ratingIssueReferenceId: 'def456',
    ratingDecisionReferenceId: null,
    ratingIssueProfileDate: '2020-04-07T00:00:00.000Z',
    approxDecisionDate: '2020-05-07',
    titleOfActiveReview: null,
    rampClaimId: null,
    verifiedUnidentifiedIssue: null
  },
  {
    id: '1',
    decisionIssueId: null,
    description: 'Military Retired Pay - nonrating description',
    decisionDate: '2020-04-27',
    ineligibleReason: null,
    ineligibleDueToId: null,
    decisionReviewTitle: 'Appeal',
    contentionText: 'Military Retired Pay - nonrating description',
    vacolsId: null,
    vacolsSequenceId: null,
    vacolsIssue: null,
    endProductCleared: null,
    endProductCode: null,
    withdrawalDate: null,
    editable: true,
    examRequested: null,
    isUnidentified: null,
    notes: null,
    category: 'Military Retired Pay',
    isRating: false,
    ratingIssueReferenceId: null,
    ratingDecisionReferenceId: null,
    ratingIssueProfileDate: '1970-01-01T00:00:00.000Z',
    approxDecisionDate: '2020-04-27',
    titleOfActiveReview: null,
    rampClaimId: null,
    verifiedUnidentifiedIssue: null
  }
];

const expected = [
  {
    index: 0,
    id: '2',
    text: 'PTSD denied',
    date: '2020-05-07',
    notes: null,
    titleOfActiveReview: null,
    decisionDate: '2020-05-07T00:00:00.000Z',
    beforeAma: false,
    ineligibleReason: null,
    rampClaimId: null,
    vacolsId: null,
    vacolsSequenceId: null,
    vacolsIssue: null,
    withdrawalDate: null,
    endProductCleared: null,
    editable: true,
    examRequested: null,
    decisionIssueId: null,
    ratingIssueReferenceId: 'def456',
    ratingDecisionReferenceId: null
  },
  {
    index: 1,
    id: '1',
    text: 'Military Retired Pay - nonrating description',
    date: '2020-04-27',
    beforeAma: false,
    ineligibleReason: null,
    vacolsId: null,
    vacolsSequenceId: null,
    vacolsIssue: null,
    decisionReviewTitle: 'Appeal',
    withdrawalDate: null,
    endProductCleared: null,
    category: 'Military Retired Pay',
    editable: true,
    examRequested: null,
    decisionIssueId: null
  }
];

describe('formatAddedIssues', () => {
  test('returns correctly formatted issues', () => {
    const res = formatAddedIssues(addedIssues);

    expect(res).toMatchSnapshot();
    expect(res[1]).toMatchObject(expected[1]);
  });
});
