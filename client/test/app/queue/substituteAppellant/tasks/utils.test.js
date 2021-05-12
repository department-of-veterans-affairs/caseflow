import { sampleEvidenceSubmissionTasks } from 'test/data/queue/substituteAppellant/tasks';
import { calculateEvidenceSubmissionEndDate } from 'app/queue/substituteAppellant/tasks/utils';
import { format } from 'date-fns';

describe('calculateEvidenceSubmissionEndDate', () => {
  const tasks = sampleEvidenceSubmissionTasks();

  it('outputs the expected result', () => {
    const args = { substitutionDate: new Date('2021-03-25'), veteranDateOfDeath: new Date('2021-03-20'), selectedTasks: tasks };
    const result = calculateEvidenceSubmissionEndDate(args);

    expect(format(result, 'yyyy-MM-dd')).toBe('2021-06-04');
  });

});
