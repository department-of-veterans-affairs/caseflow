import { expect } from 'chai';

import * as Actions from '../../../../app/certification/actions/Certification';
import * as Constants from '../../../../app/certification/constants/constants';

describe('.showValidationErrors', () => {
  it('should create an action to set the errors', () => {
    const erroredFields = ['otherRepresentativeType'];
    const expectedAction = {
      type: Constants.SHOW_VALIDATION_ERRORS,
      payload: {
        erroredFields
      }
    };

    expect(Actions.showValidationErrors(erroredFields)).to.eql(expectedAction);
  });
});
