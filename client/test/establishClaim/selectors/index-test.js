import { getStationOfJurisdiction } from '../../../app/establishClaim/selectors';
import { expect } from 'chai';

describe('EstablishClaim selectors', () => {
  context('.setStationOfJurisdictionAction', () => {
    it('defaults to ARC', () => {
      let result = getStationOfJurisdiction({}, '300');

      expect(result).to.equal('397');
    });

    it('sets SOJ to regional office', () => {
      let stationKey = '300';
      let result = getStationOfJurisdiction(
        { radiation: true },
        stationKey
      );

      expect(result).to.equal(stationKey);
    });

    it('sets SOJ to special issue\'s station', () => {
      let result = getStationOfJurisdiction(
        { foreignClaimCompensationClaimsDualClaimsAppeals: true },
        '300'
      );

      expect(result).to.equal('311');
    });

  });
});
