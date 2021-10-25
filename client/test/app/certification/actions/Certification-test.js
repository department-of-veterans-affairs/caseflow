import * as Actions from '../../../../app/certification/actions/Certification';
import * as Constants from '../../../../app/certification/constants/constants';

describe('.showValidationErrors', () => {
  it('should create an action to set the errors', () => {
    const erroredFields = ['otherRepresentativeType'];
    const scrollToError = true;
    const expectedAction = {
      type: Constants.SHOW_VALIDATION_ERRORS,
      payload: {
        erroredFields,
        scrollToError
      }
    };

    expect(Actions.showValidationErrors(erroredFields, scrollToError)).toEqual(expectedAction);
  });
});
