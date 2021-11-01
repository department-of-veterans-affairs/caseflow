import * as Actions from '../../../../app/certification/actions/ConfirmCaseDetails';
import * as Constants from '../../../../app/certification/constants/constants';

describe('.updateProgressBar', () => {
  it('should create an action to update the progress bar', () => {
    const expectedAction = {
      type: Constants.UPDATE_PROGRESS_BAR,
      payload: {
        currentSection: Constants.progressBarSections.CONFIRM_CASE_DETAILS
      }
    };

    expect(Actions.updateProgressBar()).toEqual(expectedAction);
  });
});

describe('.changeRepresentativeName', () => {
  it('should create an action to change the representative name', () => {
    const representativeName = 'new name';
    const expectedAction = {
      type: Constants.CHANGE_REPRESENTATIVE_NAME,
      payload: {
        representativeName
      }
    };

    expect(Actions.changeRepresentativeName(representativeName)).toEqual(expectedAction);
  });
});

describe('.changeRepresentativeType', () => {
  it('should create an action to change the representative type', () => {
    const representativeType = 'new type';
    const expectedAction = {
      type: Constants.CHANGE_REPRESENTATIVE_TYPE,
      payload: {
        representativeType
      }
    };

    expect(Actions.changeRepresentativeType(representativeType)).toEqual(expectedAction);
  });
});

describe('.changeOtherRepresentativeType', () => {
  it('should create an action to change the other representative type', () => {
    const otherRepresentativeType = 'new other type';
    const expectedAction = {
      type: Constants.CHANGE_OTHER_REPRESENTATIVE_TYPE,
      payload: {
        otherRepresentativeType
      }
    };

    expect(Actions.changeOtherRepresentativeType(otherRepresentativeType)).toEqual(expectedAction);
  });
});

describe('.changePoaMatches', () => {
  it('should create an action to change poaMatches', () => {
    const poaMatches = Constants.poaMatches.NO_MATCH;
    const expectedAction = {
      type: Constants.CHANGE_POA_MATCHES,
      payload: {
        poaMatches
      }
    };

    expect(Actions.changePoaMatches(poaMatches)).toEqual(expectedAction);
  });
});

describe('.changePoaCorrectLocation', () => {
  it('should create an action to change the poa correct location', () => {
    const poaCorrectLocation = Constants.poaCorrectLocation.VACOLS;
    const expectedAction = {
      type: Constants.CHANGE_POA_CORRECT_LOCATION,
      payload: {
        poaCorrectLocation
      }
    };

    expect(Actions.changePoaCorrectLocation(poaCorrectLocation)).toEqual(expectedAction);
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
      representativeType: 'ATTORNEY',
      representativeName: 'my attorney'
    };
    const expectedAction = {
      type: Constants.CERTIFICATION_UPDATE_REQUEST,
      payload: {
        update: {
          poa_correct_in_bgs: false,
          poa_correct_in_vacols: false,
          poa_matches: false,
          representative_type: 'ATTORNEY',
          representative_name: 'my attorney'
        }
      }
    };

    expect(Actions.certificationUpdateStart(params, dispatch)).toEqual(expectedAction);
  });
});
