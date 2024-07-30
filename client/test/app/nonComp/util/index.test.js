import { taskFilterDetails } from '../../../data/taskFilterDetails';
import { buildDecisionReviewFilterInformation } from 'app/nonComp/util/index';

const subject = (filterData) => buildDecisionReviewFilterInformation(filterData);

describe('Parsing filter data', () => {
  it('From in progress tasks', () => {
    const results = subject(taskFilterDetails.in_progress);

    expect(results.filterOptions).toEqual([
      {
        value: 'BoardGrantEffectuationTask',
        displayText: 'Board Grant (6)',
        checked: false
      },
      {
        value: 'HigherLevelReview',
        displayText: 'Higher-Level Review (330)',
        checked: false
      },
      {
        value: 'SupplementalClaim',
        displayText: 'Supplemental Claim (20)',
        checked: false
      },
      {
        value: 'VeteranRecordRequest',
        displayText: 'Record Request (54)',
        checked: false
      }
    ]);
  });

  it('From completed tasks', () => {
    const results = subject(taskFilterDetails.completed);

    expect(results.filterOptions).toEqual([
      {
        value: 'HigherLevelReview',
        displayText: 'Higher-Level Review (12)',
        checked: false
      },
      {
        value: 'SupplementalClaim',
        displayText: 'Supplemental Claim (15)',
        checked: false
      },
      {
        value: 'VeteranRecordRequest',
        displayText: 'Record Request (3)',
        checked: false
      }
    ]);
  });
});
