import * as Actions from '../../../../app/certification/actions/SignAndCertify';
import * as Constants from '../../../../app/certification/constants/constants';

describe('.updateProgressBar', () => {
  it('should create an action to update the progress bar', () => {
    const expectedAction = {
      type: Constants.UPDATE_PROGRESS_BAR,
      payload: {
        currentSection: Constants.progressBarSections.SIGN_AND_CERTIFY
      }
    };

    expect(Actions.updateProgressBar()).toEqual(expectedAction);
  });
});

describe('.onSignAndCertifyFormChange', () => {
  it('should create an action to change the form', () => {
    const certifyingUsername = 'new name';
    const expectedAction = {
      type: Constants.CHANGE_SIGN_AND_CERTIFY_FORM,
      payload: {
        certifyingUsername
      }
    };

    expect(Actions.onSignAndCertifyFormChange('certifyingUsername', certifyingUsername)).toEqual(expectedAction);
  });
});

describe('.handleServerError', () => {
  it('should create an action to mark an update failure', () => {
    const expectedAction = {
      type: Constants.HANDLE_SERVER_ERROR
    };

    expect(Actions.handleServerError()).toEqual(expectedAction);
  });
});

describe('.certificationUpdateSuccess', () => {
  it('should create an action to mark an update success', () => {
    const expectedAction = {
      type: Constants.CERTIFICATION_UPDATE_SUCCESS
    };

    expect(Actions.certificationUpdateSuccess()).toEqual(expectedAction);
  });
});

describe('.certificationUpdateStart', () => {
  const dispatch = jest.fn();

  it('should create an action to mark an update start', () => {
    const params = {
      certifyingOfficialName: 'Official Name',
      certifyingOfficialTitle: 'Official Title'
    };

    const expectedAction = {
      type: Constants.CERTIFICATION_UPDATE_REQUEST,
      payload: {}
    };

    expect(Actions.certificationUpdateStart(params, dispatch)).toEqual(expectedAction);

  });
});
