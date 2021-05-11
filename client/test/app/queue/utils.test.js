import { parseISO, sub } from 'date-fns';
import { timelineEventsFromAppeal, sortCaseTimelineEvents } from 'app/queue/utils';

describe('timelineEventsFromAppeal', () => {
  const decisionDate = parseISO('2021-05-01');
  const substitutionDate = parseISO('2021-05-10');

  it('returns event item for decisionDate', () => {
    const appeal = { decisionDate, substitutionDate: null };
    const res = timelineEventsFromAppeal({ appeal });

    expect(res.length).toBe(1);
    expect(res[0].type).toBe('decisionDate');
    expect(res[0].createdAt).toBe(decisionDate);
    expect(res).toMatchSnapshot();
  });

  it('returns all event items for substitutionDate', () => {
    const appeal = {
      decisionDate,
      appellantSubstitution: { substitution_date: substitutionDate },
    };
    const res = timelineEventsFromAppeal({ appeal });

    expect(res.length).toBe(2);
    expect(res).toContainEqual({
      type: 'decisionDate',
      createdAt: decisionDate,
    });
    expect(res).toContainEqual({
      type: 'substitutionDate',
      createdAt: substitutionDate,
    });

    expect(res).toMatchSnapshot();
  });
});

describe('sortCaseTimelineEvents', () => {
  const decisionDate = parseISO('2021-05-01');
  const substitutionDate = parseISO('2021-05-10');
  const appealEvents = [
    { type: 'decisionDate', createdAt: decisionDate },
    { type: 'substitutionDate', createdAt: substitutionDate },
  ];

  const tasks = [
    { type: 'RootTask', createdAt: sub(decisionDate, { days: 10 }) },
    { type: 'DistributionTask', createdAt: sub(decisionDate, { days: 10 }) },
    { type: 'JudgeAssignTask', createdAt: sub(decisionDate, { days: 8 }) },
    { type: 'JudgeDecisionTask', createdAt: sub(decisionDate, { days: 7 }) },
    { type: 'AttorneyTask', createdAt: sub(decisionDate, { days: 6 }) },
  ];

  it('properly sorts timeline events', () => {
    const res = sortCaseTimelineEvents(tasks, appealEvents);

    expect(res.length).toBe(tasks.length + appealEvents.length);

    //   expect(res).toMatchSnapshot();
  });
});
