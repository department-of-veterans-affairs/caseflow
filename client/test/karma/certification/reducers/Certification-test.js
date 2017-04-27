import { expect } from 'chai';
import * as Certification from
    '../../../../app/certification/reducers/Certification';
import { mapDataToInitialState } from
    '../../../../app/certification/reducers/index';
import * as Constants from
    '../../../../app/certification/constants/constants';

describe('.updateProgressBar', () => {
  it('should update the progress bar', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });
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

describe('.onContinueClickFailed', () => {
  it('should update continueClicked', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });
    let action = {
      type: Constants.ON_CONTINUE_CLICK_FAILED,
      payload: {
        continueClicked: true
      }
    };

    expect(Certification.onContinueClickFailed(initialState, action).
        continueClicked).to.eq(true);
  });
});

describe('.onContinueClickSuccess', () => {
  it('should update continueClicked', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });
    let action = {
      type: Constants.ON_CONTINUE_CLICK_SUCCESS,
      payload: {
        continueClicked: false
      }
    };

    expect(Certification.onContinueClickSuccess(initialState, action).
      continueClicked).to.eq(false);
  });
});

describe('.startUpdateCertification', () => {
  it('should set loading to true', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });

    expect(Certification.startUpdateCertification(initialState).
      loading).to.eq(true);
  });
});

describe('.certificationUpdateFailure', () => {
  it('should set loading to false', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });

    expect(Certification.certificationUpdateFailure(initialState).
      loading).to.eq(false);
  });
  it('should set updateFailed to true', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });

    expect(Certification.certificationUpdateFailure(initialState).
      updateFailed).to.eq(true);
  });
});

describe('.certificationUpdateSuccess', () => {
  it('should set loading to false', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });

    expect(Certification.certificationUpdateSuccess(initialState).
      loading).to.eq(false);
  });
  it('should set updateSucceeded to true', () => {
    let initialState = mapDataToInitialState({
      appeal: {},
      form8: {}
    });

    expect(Certification.certificationUpdateSuccess(initialState).
      updateSucceeded).to.eq(true);
  });
});
