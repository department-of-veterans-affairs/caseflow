import {
  appealHasDeathDismissal,
  appealHasSubstitution,
  appealSupportsSubstitution,
  supportsSubstitutionPostDispatch,
  supportsSubstitutionPreDispatch,
  isAppealDispatched,
  isSubstitutionSameAppeal } from 'app/queue/substituteAppellant/caseDetails/utils';

describe('appealHasDeathDismissal', () => {
  const appeal = {
    isLegacyAppeal: false
  };

  describe('without decision issue', () => {
    const decisionIssues = [];

    it('returns false', () => {
      expect(appealHasDeathDismissal({ ...appeal, decisionIssues })).toBe(false);
    });
  });

  describe('without dismissed_death disposition', () => {
    const decisionIssues = [{ id: 1, disposition: 'allowed' }, { id: 2, disposition: 'denied' }];

    it('returns false', () => {
      expect(appealHasDeathDismissal({ ...appeal, decisionIssues })).toBe(false);
    });
  });

  describe('with dismissed_death disposition', () => {
    const
      decisionIssues = [
        { id: 1, disposition: 'allowed' },
        { id: 2, disposition: 'dismissed_death' },
      ];

    it('returns true', () => {
      expect(appealHasDeathDismissal({ ...appeal, decisionIssues })).toBe(true);
    });
  });
});

describe('appealHasSubstitution', () => {
  describe('appeal has existing substitution', () => {
    const appeal = { substitutions: [{ source_appeal_id: 1, target_appeal_id: 2 }] };

    it('returns true', () => {
      expect(appealHasSubstitution(appeal)).toBe(true);
    });
  });

  describe('appeal has no existing substitution', () => {
    const appeal = { substitutions: [] };

    it('returns false', () => {
      expect(appealHasSubstitution(appeal)).toBe(false);
    });
  });
});

describe('appealSupportsSubstitution', () => {
  test('requires AMA appeal', () => {
    const legacyAppeal = { isLegacyAppeal: true };

    expect(appealSupportsSubstitution(legacyAppeal)).toBe(false);
  });

  test('requires `original` appeal stream type', () => {
    const remandAppeal = { caseType: 'Remand' };

    expect(appealSupportsSubstitution(remandAppeal)).toBe(false);
  });

  test('requires veteran appellant', () => {
    const appeal = { appellantIsNotVeteran: true };

    expect(appealSupportsSubstitution(appeal)).toBe(false);
  });

  test('requires all params', () => {
    const appeal = { isLegacyAppeal: false, caseType: 'Original', appellantIsNotVeteran: false };

    expect(appealSupportsSubstitution(appeal)).toBe(true);
  });
});

describe('supportsSubstitutionPreDispatch', () => {
  const appeal = {
    appellantIsNotVeteran: false,
    caseType: 'Original',
    decisionIssues: [],
    docketName: 'direct_review',
    isLegacyAppeal: false,
    veteranAppellantDeceased: true
  };
  const featureToggles = {
    listed_granted_substitution_before_dismissal: true,
  };
  const defaults = {
    appeal,
    currentUserOnClerkOfTheBoard: true,
    featureToggles,
    userIsCobAdmin: false,
    hasSubstitution: false,
  };

  describe('with requisite values', () => {
    it('returns true', () => {
      const args = { ...defaults };

      expect(supportsSubstitutionPreDispatch(args)).toBe(true);
    });
  });

  describe('with appeal.appellantIsNotVeteran', () => {
    it('returns false', () => {
      const args = {
        ...defaults,
        appeal: { ...appeal, appellantIsNotVeteran: true },
      };

      expect(supportsSubstitutionPreDispatch(args)).toBe(false);
    });
  });

  describe('with other caseTypes', () => {
    const ineligibleCaseTypes = ['vacate', 'de_novo', 'court_remand'];

    it.each(ineligibleCaseTypes)('for %s, returns false', (caseType) => {
      const args = { ...defaults, appeal: { ...appeal, caseType } };

      expect(supportsSubstitutionPreDispatch(args)).toBe(false);
    });
  });

  describe('when not AMA appeal', () => {
    it('returns false', () => {
      const args = { ...defaults, appeal: { ...appeal, isLegacyAppeal: true } };

      expect(supportsSubstitutionPreDispatch(args)).toBe(false);
    });
  });

  describe('with existing substitution', () => {
    it('returns false', () => {
      const args = { ...defaults, hasSubstitution: true };

      expect(supportsSubstitutionPreDispatch(args)).toBe(false);
    });
  });

  describe('with non-COB user', () => {
    it('returns false', () => {
      const args = { ...defaults, currentUserOnClerkOfTheBoard: false };

      expect(supportsSubstitutionPreDispatch(args)).toBe(false);
    });
  });

  describe('when not death dismissal', () => {
    const nonDismissedDecisionIssues = [
      { id: 1, disposition: 'something_else' },
    ];
    const testAppeal = {
      ...appeal,
      decisionIssues: nonDismissedDecisionIssues,
      veteranAppellantDeceased: false,
    };

    describe('with regular COB user', () => {
      it('returns false', () => {
        const args = { ...defaults, appeal: testAppeal };

        expect(supportsSubstitutionPreDispatch(args)).toBe(false);
      });
    });

    describe('with COB admin', () => {
      it('returns true', () => {
        const args = { ...defaults, appeal: testAppeal, userIsCobAdmin: true };

        expect(supportsSubstitutionPreDispatch(args)).toBe(true);
      });
    });
  });
});

describe('supportsSubstitutionPostDispatch', () => {
  const appeal = {
    appellantIsNotVeteran: false,
    caseType: 'Original',
    decisionIssues: [{ id: 1, disposition: 'dismissed_death' }],
    docketName: 'direct_review',
    isLegacyAppeal: false,
  };
  const defaults = {
    appeal,
    currentUserOnClerkOfTheBoard: true,
    hasSubstitution: false,
    userIsCobAdmin: false,
  };

  describe('with requisite values', () => {
    it('returns true', () => {
      const args = { ...defaults };

      expect(supportsSubstitutionPostDispatch(args)).toBe(true);
    });
  });

  describe('with appeal.appellantIsNotVeteran', () => {
    it('returns false', () => {
      const args = {
        ...defaults,
        appeal: { ...appeal, appellantIsNotVeteran: true },
      };

      expect(supportsSubstitutionPostDispatch(args)).toBe(false);
    });
  });

  describe('with other caseTypes', () => {
    const ineligibleCaseTypes = ['vacate', 'de_novo', 'court_remand'];

    it.each(ineligibleCaseTypes)('for %s, returns false', (caseType) => {
      const args = { ...defaults, appeal: { ...appeal, caseType } };

      expect(supportsSubstitutionPostDispatch(args)).toBe(false);
    });
  });

  describe('when not AMA appeal', () => {
    it('returns false', () => {
      const args = { ...defaults, appeal: { ...appeal, isLegacyAppeal: true } };

      expect(supportsSubstitutionPostDispatch(args)).toBe(false);
    });
  });

  describe('with existing substitution', () => {
    it('returns false', () => {
      const args = { ...defaults, hasSubstitution: true };

      expect(supportsSubstitutionPostDispatch(args)).toBe(false);
    });
  });

  describe('with non-COB user', () => {
    it('returns false', () => {
      const args = { ...defaults, currentUserOnClerkOfTheBoard: false };

      expect(supportsSubstitutionPostDispatch(args)).toBe(false);
    });
  });

  describe('when not death dismissal', () => {
    const nonDismissedDecisionIssues = [
      { id: 1, disposition: 'something_else' },
    ];
    const testAppeal = {
      ...appeal,
      decisionIssues: nonDismissedDecisionIssues,
    };

    describe('with regular COB user', () => {
      it('returns false', () => {
        const args = { ...defaults, appeal: testAppeal };

        expect(supportsSubstitutionPostDispatch(args)).toBe(false);
      });
    });

    describe('with COB admin', () => {
      it('returns true', () => {
        const args = { ...defaults, appeal: testAppeal, userIsCobAdmin: true };

        expect(supportsSubstitutionPostDispatch(args)).toBe(true);
      });
    });
  });

  describe('with hearing docket', () => {
    const hearingAppeal = { ...appeal, docketName: 'hearing' };

    it('returns true', () => {
      const args = { ...defaults, appeal: hearingAppeal };

      expect(supportsSubstitutionPostDispatch(args)).toBe(true);
    });
  });
});

describe('isAppealDispatched', () => {
  it('returns true for an appeal post dispatch', () => {
    const appealPostDispatch = {
      status: 'post_dispatch'
    };

    expect(isAppealDispatched(appealPostDispatch)).toBe(true);
  });

  it('returns true for a dispatched appeal', () => {
    const appealDispatched = {
      status: 'dispatched'
    };

    expect(isAppealDispatched(appealDispatched)).toBe(true);
  });

  it('returns false for a pre dispatch appeal', () => {
    const appealPreDispatch = {
      status: 'in_progress'
    };

    expect(isAppealDispatched(appealPreDispatch)).toBe(false);
  });
});

describe('isSubstitutionSameAppeal', () => {
  describe('pre dispatch appeal', () => {
    const appeal = {
      status: 'in_progress',
    };

    it('returns true', () => {
      expect(isSubstitutionSameAppeal(appeal)).toBe(true);
    });
  });

  describe('dispatched appeal', () => {
    const appeal = {
      status: 'post_dispatch',
    };

    it('returns false for an appeal with a death dismissal', () => {
      const decisionIssues = [{
        disposition: 'dismissed_death'
      }];

      expect(isSubstitutionSameAppeal({ ...appeal, decisionIssues })).toBe(false);
    });

    it('returns false for an appeal with no death dismissal', () => {
      const decisionIssues = [];

      expect(isSubstitutionSameAppeal({ ...appeal, decisionIssues })).toBe(false);
    });
  });

});
