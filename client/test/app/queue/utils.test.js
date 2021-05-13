import { parseISO, sub } from 'date-fns';
import {
  timelineEventsFromAppeal,
  sortCaseTimelineEvents,
} from 'app/queue/utils';

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
  const decisionDate = parseISO('2021-05-01 12:00');
  const substitutionDate = sub(decisionDate, { days: 20 });
  const appealEvents = [{ type: 'decisionDate', createdAt: decisionDate }];

  const tasks = [
    {
      type: 'RootTask',
      createdAt: sub(decisionDate, { days: 10, seconds: 10 }),
    },
    {
      type: 'DistributionTask',
      createdAt: sub(decisionDate, { days: 10, seconds: 5 }),
    },
    { type: 'JudgeAssignTask', createdAt: sub(decisionDate, { days: 8 }) },
    { type: 'JudgeDecisionTask', createdAt: sub(decisionDate, { days: 7 }) },
    { type: 'AttorneyTask', createdAt: sub(decisionDate, { days: 6 }) },
  ];

  describe('with basic post-distribution tasks', () => {
    it('properly sorts timeline events', () => {
      const res = sortCaseTimelineEvents(tasks, appealEvents);

      expect(res.length).toBe(tasks.length + appealEvents.length);
      expect(res[0].type).toBe('decisionDate');
      expect(res).toMatchSnapshot();
    });
  });

  describe('with NOD date updates', () => {
    const appealEventsWithNodUpdate = [
      ...appealEvents,
      { type: 'nodDateUpdate', createdAt: sub(decisionDate, { days: 9 }) },
    ];

    it('sorts the substitution date item into proper place', () => {
      const res = sortCaseTimelineEvents(tasks, appealEventsWithNodUpdate);

      expect(res.length).toBe(tasks.length + appealEventsWithNodUpdate.length);
      expect(res[0].type).toBe('decisionDate');
      expect(res[4].type).toBe('nodDateUpdate');
      expect(res).toMatchSnapshot();
    });
  });

  describe('with substitution date', () => {
    const appealEventsWithSubstitution = [
      ...appealEvents,
      { type: 'substitutionDate', createdAt: substitutionDate },
    ];

    it('sorts the substitution date item into proper place', () => {
      const res = sortCaseTimelineEvents(tasks, appealEventsWithSubstitution);

      expect(res.length).toBe(
        tasks.length + appealEventsWithSubstitution.length
      );
      expect(res[0].type).toBe('decisionDate');
      expect(res[res.length - 1].type).toBe('substitutionDate');
      expect(res).toMatchSnapshot();
    });
  });

  describe('without decision date', () => {
    const appealEventsWithoutDecision = [
      { type: 'decisionDate', createdAt: Number.NEGATIVE_INFINITY },
    ];

    it('sorts the unset decision date at the top to show pending', () => {
      const res = sortCaseTimelineEvents(tasks, appealEventsWithoutDecision);

      expect(res[0].type).toBe('decisionDate');
      expect(res).toMatchSnapshot();
    });

    describe('with substitution date', () => {
      it('sorts the substitution date item into proper place', () => {
        const appealEventsWithSubstitution = [
          ...appealEventsWithoutDecision,
          { type: 'substitutionDate', createdAt: substitutionDate },
        ];
        const res = sortCaseTimelineEvents(tasks, appealEventsWithSubstitution);

        expect(res.length).toBe(
          tasks.length + appealEventsWithSubstitution.length
        );
        expect(res[0].type).toBe('decisionDate');
        expect(res[res.length - 1].type).toBe('substitutionDate');
        expect(res).toMatchSnapshot();
      });
    });
  });
});
