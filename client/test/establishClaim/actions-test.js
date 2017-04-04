import * as Actions from '../../app/establishClaim/actions/actions';
import { expect } from 'chai';

describe('EstablishClaim Actions', () => {
  context('.setStationOfJurisdictionAction', () => {
    it('sets field key', () => {
      let action = Actions.setStationOfJurisdictionAction({}, '300');
      expect(action.payload.field).to.equal('stationOfJurisdiction');
    });

    it('defaults to ARC', () => {
      let action = Actions.setStationOfJurisdictionAction({}, '300');
      expect(action.payload.value).to.equal('397 - ARC');
    });

    it('sets SOJ to regional office', () => {
      let stationKey = '300';
      let action = Actions.setStationOfJurisdictionAction(
        { radiation: true },
        stationKey
      );
      expect(action.payload.value).to.equal(stationKey);
    });

    it('sets SOJ to special issue\'s station', () => {
      let action = Actions.setStationOfJurisdictionAction(
        { foreignClaimCompensationClaimsDualClaimsAppeals: true },
        '300'
      );
      expect(action.payload.value).to.equal('311 - Pittsburgh, PA');
    });

  });
});
