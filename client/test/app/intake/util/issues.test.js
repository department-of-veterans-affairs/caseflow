import { formatAddedIssues, getAddIssuesFields } from 'app/intake/util/issues';
import { getAddIssuesFieldsSamples } from '../../../data/intake/intakes';

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

const testVeteran = 'Bob Something (000000001)';

const intakesCases = {
  docketTypeNotHearing: 0,
  hearingTypeNull: 1,
  hearingTypePresent: 2,
};

const hearingTypeIsPresent = (fields) => {
  // findIndex returns -1 if an entry with field = 'hearing type' isn't found.
  let idx = fields.findIndex((entry) => entry.field.toLowerCase() === 'hearing type');

  return idx !== -1;
};

describe('formatAddedIssues', () => {
  describe('nonrating issues', () => {
    describe('adding new', () => {
      // Here we expect it to prepend the category to the text description
      const issues = addedIssues.map((issue) => ({
        ...issue,
        id: null,
        description: issue.description.replace(`${issue.category} - `, '')
      }));

      test('returns correctly formatted issues', () => {
        const res = formatAddedIssues(issues);

        expect(res).toMatchSnapshot();
        expect(res[1]).toMatchObject({ ...expected[1], id: null });
      });
    });

    describe('editing existing', () => {
      test('returns correctly formatted issues', () => {
        // Here the text description already contains category, so we shouldn't be prepending
        const res = formatAddedIssues(addedIssues);

        expect(res).toMatchSnapshot();
        expect(res[1]).toMatchObject(expected[1]);
      });
    });
  });
});

describe('getAddIssueFields - form_type: appeal - Hearing type field', () => {
  it('is not present because docket type is not hearing', async () => {
    const fields = getAddIssuesFields(
      'appeal',
      testVeteran,
      getAddIssuesFieldsSamples[intakesCases.docketTypeNotHearing]
    );

    expect(hearingTypeIsPresent(fields)).toBe(false);
  });

  it('is not present because hearing type is null despite docket type being hearing', async () => {
    const fields = getAddIssuesFields(
      'appeal',
      testVeteran,
      getAddIssuesFieldsSamples[intakesCases.hearingTypeNull]
    );

    expect(hearingTypeIsPresent(fields)).toBe(false);
  });

  it('is present because docket type is hearing and hearing type is not null', async () => {
    const fields = getAddIssuesFields(
      'appeal',
      testVeteran,
      getAddIssuesFieldsSamples[intakesCases.hearingTypePresent]
    );

    expect(hearingTypeIsPresent(fields)).toBe(true);
  });
});

