import { showValidationErrors } from '../../../app/certification/actions/Certification';
import { SHOW_VALIDATION_ERRORS } from '../../../app/certification/constants/constants';

describe('Certification', () => {
  it('should create an action to set the errors', () => {
    const erroredFields = ['otherRepresentativeType'];
    const scrollToError = true;
    const expectedAction = {
      type: SHOW_VALIDATION_ERRORS,
      payload: {
        erroredFields,
        scrollToError
      }
    };

    expect(showValidationErrors(erroredFields, scrollToError)).toEqual(expectedAction);
  });
});
