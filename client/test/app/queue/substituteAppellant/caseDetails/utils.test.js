import { shouldSupportSubstituteAppellant } from 'app/queue/substituteAppellant/caseDetails/utils';

describe('shouldSupportSubstituteAppellant', () => {
  const appeal = {
    appellantIsNotVeteran: false,
    caseType: 'Original',
    decisionIssues: [{ id: 1, disposition: 'dismissed_death' }],
    docketName: 'direct_review',
    isLegacyAppeal: false,
  };
  const featureToggles = {
    recognized_granted_substitution_after_dd: true,
    hearings_substitution_death_dismissal: true,
  };
  const defaults = {
    appeal,
    currentUserOnClerkOfTheBoard: true,
    hasSubstitution: false,
    featureToggles,
    userIsCobAdmin: false,
  };

  describe('with sensible defaults', () => {
    it('returns true', () => {
      const args = { ...defaults };

      expect(shouldSupportSubstituteAppellant(args)).toBe(true);
    });
  });

  describe('with appeal.appellantIsNotVeteran', () => {
    it('returns false', () => {
      const args = {
        ...defaults,
        appeal: { ...appeal, appellantIsNotVeteran: true },
      };

      expect(shouldSupportSubstituteAppellant(args)).toBe(false);
    });
  });

  describe('with other caseTypes', () => {
    const ineligibleCaseTypes = ['vacate', 'de_novo', 'court_remand'];

    it.each(ineligibleCaseTypes)('for %s, returns false', (caseType) => {
      const args = { ...defaults, appeal: { ...appeal, caseType } };

      expect(shouldSupportSubstituteAppellant(args)).toBe(false);
    });
  });

  describe('when not AMA appeal', () => {
    it('returns false', () => {
      const args = { ...defaults, appeal: { ...appeal, isLegacyAppeal: true } };

      expect(shouldSupportSubstituteAppellant(args)).toBe(false);
    });
  });

  describe('without recognized_granted_substitution_after_dd feature toggle', () => {
    it('returns false', () => {
      const args = {
        ...defaults,
        featureToggles: {
          ...featureToggles,
          recognized_granted_substitution_after_dd: false,
        },
      };

      expect(shouldSupportSubstituteAppellant(args)).toBe(false);
    });
  });

  describe('with existing substitution', () => {
    it('returns false', () => {
      const args = { ...defaults, hasSubstitution: true };

      expect(shouldSupportSubstituteAppellant(args)).toBe(false);
    });
  });

  describe('with non-COB user', () => {
    it('returns false', () => {
      const args = { ...defaults, currentUserOnClerkOfTheBoard: false };

      expect(shouldSupportSubstituteAppellant(args)).toBe(false);
    });
  });

  describe('when not death dismissal', () => {
    const nonDismissedDecisionIssues = [{ id: 1, disposition: 'something_else' }];
    const testAppeal = { ...appeal, decisionIssues: nonDismissedDecisionIssues };

    describe('with regular COB user', () => {
      it('returns false', () => {
        const args = { ...defaults, appeal: testAppeal };

        expect(shouldSupportSubstituteAppellant(args)).toBe(false);
      });
    });

    describe('with COB admin', () => {
      it('returns true', () => {
        const args = { ...defaults, appeal: testAppeal, userIsCobAdmin: true };

        expect(shouldSupportSubstituteAppellant(args)).toBe(true);
      });
    });
  });

  describe('with hearing docket', () => {
    const hearingAppeal = { ...appeal, docketName: 'hearing' };

    describe('without hearings_substitution_death_dismissal feature toggle', () => {
      it('returns false', () => {
        const args = {
          ...defaults,
          appeal: hearingAppeal,
          featureToggles: {
            ...featureToggles,
            hearings_substitution_death_dismissal: false,
          },
        };

        expect(shouldSupportSubstituteAppellant(args)).toBe(false);
      });
    });

    describe('with hearings_substitution_death_dismissal feature toggle', () => {
      it('returns true', () => {
        const args = { ...defaults, appeal: hearingAppeal };

        expect(shouldSupportSubstituteAppellant(args)).toBe(true);
      });
    });
  });
});
