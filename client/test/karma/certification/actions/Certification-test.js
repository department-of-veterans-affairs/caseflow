import { expect } from 'chai';

import * as Actions from '../../../../app/certification/actions/Certification';
import * as Constants from '../../../../app/certification/constants/constants';

describe('.changeErroredFields', () => {
  it('should create an action to set the errors', () => {
    const erroredFields = ['otherRepresentativeType'];
    const expectedAction = {
      type: Constants.CHANGE_ERRORED_FIELDS,
      payload: {
        erroredFields
      }
    };

    expect(Actions.changeErroredFields(erroredFields)).to.eql(expectedAction);
  });
});