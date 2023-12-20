import { getStationOfJurisdiction } from '../../../../app/establishClaim/selectors';

describe('EstablishClaim selectors', () => {
  describe('.setStationOfJurisdictionAction', () => {
    it('defaults to ARC', () => {
      let result = getStationOfJurisdiction({}, '300');

      expect(result).toBe('397');
    });

    it('sets SOJ to regional office', () => {
      const stationKey = '300';
      const result = getStationOfJurisdiction(
        { radiation: true },
        stationKey
      );

      expect(result).toBe(stationKey);
    });

    it('sets SOJ to special issue\'s station', () => {
      const result = getStationOfJurisdiction(
        { foreignClaimCompensationClaimsDualClaimsAppeals: true },
        '300'
      );

      expect(result).toBe('311');
    });

  });
});
