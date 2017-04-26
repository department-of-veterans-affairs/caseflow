import { expect } from 'chai';
import * as ConfirmCaseDetails from
    '../../../../app/certification/reducers/ConfirmCaseDetails';
import { mapDataToInitialState } from
    '../../../../app/certification/reducers/index';
import * as Constants from
    '../../../../app/certification/constants/constants';

describe('ConfirmCaseDetailsReducer', () => {
  context('.changeRepresentativeType', () => {
    let initialState;

    beforeEach(() => {
      initialState = mapDataToInitialState({
        appeal: {},
        form8: {}
      });
    });

    let action = {
      type: Constants.CHANGE_REPRESENTATIVE_TYPE,
      payload: {
        representativeType: 'new rep type'
      }
    };

    it('changes the representative type', () => {
      expect(ConfirmCaseDetails.changeRepresentativeType(initialState, action).representativeType).to.eq('new rep type');
    });
  });
  context('.changeRepresentativeName', () => {
    let initialState;

    beforeEach(() => {
      initialState = mapDataToInitialState({
        appeal: {},
        form8: {}
      });
    });

    let action = {
      type: Constants.CHANGE_REPRESENTATIVE_NAME,
      payload: {
        representativeName: 'new rep name'
      }
    };

    it('changes the representative name', () => {
      expect(ConfirmCaseDetails.changeRepresentativeName(initialState, action).representativeName).to.eq('new rep name');
    });
  });
  context('.changeOtherRepresentativeType', () => {
    let initialState;

    beforeEach(() => {
      initialState = mapDataToInitialState({
        appeal: {},
        form8: {}
      });
    });

    let action = {
      type: Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE,
      payload: {
        otherRepresentativeType: 'new other rep type'
      }
    };

    it('changes the other representative type', () => {
      expect(ConfirmCaseDetails.changeOtherRepresentativeType(initialState, action).otherRepresentativeType).to.eq('new other rep type');
    });
  });
});
