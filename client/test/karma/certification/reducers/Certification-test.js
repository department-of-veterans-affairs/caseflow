import { expect } from 'chai';
import * as Certification from
    '../../../../app/certification/reducers/Certification';
import { getBlankInitialState } from './util';
import * as Constants from
    '../../../../app/certification/constants/constants';

describe('.updateProgressBar', () => {
  it('should update the progress bar', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.UPDATE_PROGRESS_BAR,
      payload: {
        currentSection: 'current section'
      }
    };

    expect(Certification.updateProgressBar(initialState, action).
        currentSection).to.eq('current section');
  });
});

describe('.startUpdateCertification', () => {
  it('should set loading to true', () => {
    let initialState = getBlankInitialState();

    expect(Certification.startUpdateCertification(initialState).
      loading).to.eq(true);
  });
});

describe('.showValidationErrors', () => {
  it('should show the validation errors', () => {
    let initialState = getBlankInitialState();
    let action = {
      type: Constants.SHOW_VALIDATION_ERRORS,
      payload: {
        erroredFields: ['otherRepresentativeType']
      }
    };

    expect(Certification.showValidationErrors(initialState, action).
      erroredFields).to.eql(['otherRepresentativeType']);
  });
});

describe('.certificationUpdateFailure', () => {
  it('should set loading to false', () => {
    let initialState = getBlankInitialState();

    expect(Certification.certificationUpdateFailure(initialState).
      loading).to.eq(false);
  });
  it('should set updateFailed to true', () => {
    let initialState = getBlankInitialState();

    expect(Certification.certificationUpdateFailure(initialState).
      updateFailed).to.eq(true);
  });
});

describe('.certificationUpdateSuccess', () => {
  it('should set loading to false', () => {
    let initialState = getBlankInitialState();

    expect(Certification.certificationUpdateSuccess(initialState).
      loading).to.eq(false);
  });
  it('should set updateSucceeded to true', () => {
    let initialState = getBlankInitialState();

    expect(Certification.certificationUpdateSuccess(initialState).
      updateSucceeded).to.eq(true);
  });
});
