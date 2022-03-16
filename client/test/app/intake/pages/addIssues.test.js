import { getAddIssuesFields } from 'app/intake/util/issues';
import { getAddIssuesFieldsSamples } from '../../../data/intake/intakes'

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
