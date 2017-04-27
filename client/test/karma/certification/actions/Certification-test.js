import { expect } from 'chai';

import * as Actions from '../../../../app/certification/actions/Certification';
import * as Constants from '../../../../app/certification/constants/constants';

describe('.onContinueClickFailed', () => {
  it('should create an action to set continueClicked to true', () => {
    const expectedAction = {
      type: Constants.ON_CONTINUE_CLICK_FAILED,
      payload: {
        continueClicked: true
      }
    };

    expect(Actions.onContinueClickFailed()).to.eql(expectedAction);
  });
});

describe('.onContinueClickSuccess', () => {
  it('should create an action to set continueClicked to false', () => {
    const expectedAction = {
      type: Constants.ON_CONTINUE_CLICK_SUCCESS,
      payload: {
        continueClicked: false
      }
    };

    expect(Actions.onContinueClickSuccess()).to.eql(expectedAction);
  });
});
