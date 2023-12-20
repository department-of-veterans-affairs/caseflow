import { shouldShowVsoVisibilityAlert } from 'app/queue/caseDetails/utils';

describe('shouldShowVsoVisibilityAlert', () => {
  const itReturnsFalse = ({ featureToggles, userIsVsoEmployee }) => {
    it('returns false', () => {
      expect(
        shouldShowVsoVisibilityAlert({ featureToggles, userIsVsoEmployee })
      ).toBe(false);
    });
  };
  const itReturnsTrue = ({ featureToggles, userIsVsoEmployee }) => {
    it('returns true', () => {
      expect(
        shouldShowVsoVisibilityAlert({ featureToggles, userIsVsoEmployee })
      ).toBe(true);
    });
  };

  describe('with non-vso user', () => {
    const userIsVsoEmployee = false;

    describe('with feature toggle', () => {
      const featureToggles = { restrict_poa_visibility: true };

      itReturnsFalse({ featureToggles, userIsVsoEmployee });
    });

    describe('without feature toggle', () => {
      const featureToggles = { restrict_poa_visibility: false };

      itReturnsFalse({ featureToggles, userIsVsoEmployee });
    });
  });
  describe('with vso user', () => {
    const userIsVsoEmployee = true;

    describe('with feature toggle', () => {
      const featureToggles = { restrict_poa_visibility: true };

      itReturnsTrue({ featureToggles, userIsVsoEmployee });
    });

    describe('without feature toggle', () => {
      const featureToggles = { restrict_poa_visibility: false };

      itReturnsFalse({ featureToggles, userIsVsoEmployee });
    });
  });
});
