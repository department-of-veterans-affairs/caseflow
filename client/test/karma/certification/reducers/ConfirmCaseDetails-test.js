import { expect } from 'chai';
import * as ConfirmCaseDetails from
  '../../../../app/certification/reducers/ConfirmCaseDetails';
import { getBlankInitialState } from './util';
import * as Constants from
  '../../../../app/certification/constants/constants';

describe('.changeRepresentativeType', () => {
  it('should change the representative type', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.CHANGE_REPRESENTATIVE_TYPE,
      payload: {
        representativeType: 'new rep type'
      }
    };

    expect(ConfirmCaseDetails.changeRepresentativeType(initialState, action).
      representativeType).to.eq('new rep type');
  });
});

describe('.changeRepresentativeName', () => {
  it('should change the representative name', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.CHANGE_REPRESENTATIVE_NAME,
      payload: {
        representativeName: 'new rep name'
      }
    };

    expect(ConfirmCaseDetails.changeRepresentativeName(initialState, action).
      representativeName).to.eq('new rep name');
  });
});

describe('.changeOtherRepresentativeType', () => {
  it('should change the other representative type', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE,
      payload: {
        otherRepresentativeType: 'new other rep type'
      }
    };

    expect(ConfirmCaseDetails.changeOtherRepresentativeType(initialState, action).
      otherRepresentativeType).to.eq('new other rep type');
  });
});

describe('.changePoaMatches', () => {
  it('should change the poaMatches field', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.CHANGE_POA_MATCHES,
      payload: {
        poaMatches: 'MATCH'
      }
    };

    expect(ConfirmCaseDetails.changePoaMatches(initialState, action).
      poaMatches).to.eq('MATCH');
  });
});

describe('.changePoaCorrectLocation', () => {
  it('should change the correct poa location', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.CHANGE_POA_CORRECT_LOCATION,
      payload: {
        poaCorrectLocation: Constants.poaCorrectLocation.VACOLS
      }
    };

    expect(ConfirmCaseDetails.changePoaCorrectLocation(initialState, action).
      poaCorrectLocation).to.eq(Constants.poaCorrectLocation.VACOLS);
  });
});
