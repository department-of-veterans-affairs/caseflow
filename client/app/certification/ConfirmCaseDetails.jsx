// TODO refactor into smaller files
/* eslint max-lines: ["error", 520]*/
import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as actions from './actions/ConfirmCaseDetails';
import * as certificationActions from './actions/Certification';
import { Redirect } from 'react-router-dom';

import ValidatorsUtil from '../util/ValidatorsUtil';
import RadioField from '../components/RadioField';
import Table from '../components/Table';
import Footer from './Footer';
import Dropdown from '../components/Dropdown';
import TextField from '../components/TextField';
import Header from './Header';
import CertificationProgressBar from './CertificationProgressBar';

const poaMatchesOptions = [
  { displayText: 'Yes',
    value: Constants.poaMatches.MATCH },
  { displayText: 'No',
    value: Constants.poaMatches.NO_MATCH }
];

const poaCorrectLocationOptions = [
  { displayText: 'VBMS',
    value: Constants.poaCorrectLocation.VBMS },
  { displayText: 'VACOLS',
    value: Constants.poaCorrectLocation.VACOLS },
  { displayText: 'None of the above',
    value: Constants.poaCorrectLocation.NONE }
];

const representativeTypeOptions = [
  { displayText: 'Attorney',
    value: Constants.representativeTypes.ATTORNEY },
  { displayText: 'Agent',
    value: Constants.representativeTypes.AGENT },
  { displayText: 'Service organization',
    value: Constants.representativeTypes.ORGANIZATION },
  { displayText: 'Other',
    value: Constants.representativeTypes.OTHER },
  { displayText: 'No representative',
    value: Constants.representativeTypes.NONE }
];

const organizationNamesOptions = [
  { displayText: 'AMVETS',
    value: Constants.organizationNames.AMVETS },
  { displayText: 'American Ex-Prisoners of War',
    value: Constants.organizationNames.AMERICAN_EX_PRISONERS_OF_WAR },
  { displayText: 'American Red Cross',
    value: Constants.organizationNames.AMERICAN_RED_CROSS },
  { displayText: 'Army & Air Force Mutual Aid Assn.',
    value: Constants.organizationNames.ARMY_AND_AIR_FORCE_MUTUAL_AID_ASSN },
  { displayText: 'Blinded Veterans Association',
    value: Constants.organizationNames.BLINDED_VETERANS_ASSOCIATION },
  { displayText: 'Catholic War Veterans',
    value: Constants.organizationNames.CATHOLIC_WAR_VETERANS },
  { displayText: 'Disabled American Veterans',
    value: Constants.organizationNames.DISABLED_AMERICAN_VETERANS },
  { displayText: 'Fleet Reserve Association',
    value: Constants.organizationNames.FLEET_RESERVE_ASSOCIATION },
  { displayText: 'Jewish War Veterans',
    value: Constants.organizationNames.JEWISH_WAR_VETERANS },
  { displayText: 'Marine Corp League',
    value: Constants.organizationNames.MARINE_CORP_LEAGUE },
  { displayText: 'Maryland Veterans Commission',
    value: Constants.organizationNames.MARYLAND_VETERANS_COMMISSION },
  { displayText: 'Military Order of the Purple Heart',
    value: Constants.organizationNames.MILITARY_ORDER_OF_THE_PURPLE_HEART },
  { displayText: 'National Veterans Legal Services Program',
    value: Constants.organizationNames.NATIONAL_VETERANS_LEGAL_SERVICES_PROGRAM },
  { displayText: 'National Veterans Organization of America',
    value: Constants.organizationNames.NATIONAL_VETERANS_ORGANIZATION_OF_AMERICA },
  { displayText: 'Navy Mutual Aid Association',
    value: Constants.organizationNames.NAVY_MUTUAL_AID_ASSOCIATION },
  { displayText: 'Non-Commissioned Officers Association',
    value: Constants.organizationNames.NON_COMMISSIONED_OFFICERS_ASSOCIATION },
  { displayText: 'Other Service Organization',
    value: Constants.organizationNames.OTHER_SERVICE_ORGANIZATION },
  { displayText: 'Paralyzed Veterans of America',
    value: Constants.organizationNames.PARALYZED_VETERANS_OF_AMERICA },
  { displayText: 'State Service Organization(s)',
    value: Constants.organizationNames.STATE_SERVICE_ORGANIZATION },
  { displayText: 'The American Legion',
    value: Constants.organizationNames.THE_AMERICAN_LEGION },
  { displayText: 'Veterans of Foreign Wars',
    value: Constants.organizationNames.VETERANS_OF_FOREIGN_WARS },
  { displayText: 'Vietnam Veterans of America',
    value: Constants.organizationNames.VIETNAM_VETERANS_OF_AMERICA },
  { displayText: 'Virginia Department of Veterans Affairs',
    value: Constants.organizationNames.VIRGINIA_DEPARTMENT_OF_VETERANS_AFFAIRS },
  { displayText: 'Wounded Warrior Project',
    value: Constants.organizationNames.WOUNDED_WARRIOR_PROJECT },
  { displayText: 'Unlisted service organization',
    value: Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION }
];

// TODO: We should give each question a constant name.
const ERRORS = {
  poaMatches: 'Please select yes or no.',
  poaCorrectLocation: 'Please select an option.',
  representativeType: 'Please select a representative type.',
  representativeName: 'Please enter a service organization\'s name.',
  organizationName: 'Please select an organization.',
  representativeNameLength: 'Maximum length of organization name reached.'
};

/*
 * This page will display information from BGS
 * about the appellant's representation for the appeal
 * and confirm it.
 *
 * On the backend, we'll then update that information in VACOLS
 * if necessary. This was created since power of attorney
 * information in VACOLS is very often out of date, which can
 * in case delays -- attorneys can't access the appeal information
 * if they're not noted as being the appellant's representative
 */

export class ConfirmCaseDetails extends React.Component {
  // TODO: updating state in UNSAFE_componentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  // eslint-disable-next-line camelcase
  UNSAFE_componentWillMount() {
    this.props.updateProgressBar();
  }

  componentWillUnmount() {
    this.props.resetState();
  }

  componentDidMount() {
    window.scrollTo(0, 0);
  }

  getValidationErrors() {
    // TODO: consider breaking this and all validation out into separate
    // modules.
    const {
      poaMatches,
      poaCorrectLocation,
      representativeType,
      organizationName,
      representativeName
    } = this.props;

    const erroredFields = [];

    if (ValidatorsUtil.requiredValidator(poaMatches)) {
      erroredFields.push('poaMatches');
    }

    if (poaMatches === Constants.poaMatches.NO_MATCH && ValidatorsUtil.requiredValidator(poaCorrectLocation)) {
      erroredFields.push('poaCorrectLocation');
    }

    if (poaCorrectLocation === Constants.poaCorrectLocation.NONE &&
     ValidatorsUtil.requiredValidator(representativeType)) {
      erroredFields.push('representativeType');
    }

    if (representativeType === Constants.representativeTypes.ORGANIZATION &&
      ValidatorsUtil.requiredValidator(organizationName)) {
      erroredFields.push('organizationName');
    }

    if (organizationName === Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION &&
     ValidatorsUtil.requiredValidator(representativeName)) {
      erroredFields.push('representativeName');
    } else if (organizationName === Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION &&
         ValidatorsUtil.lengthValidator(representativeName)) {
      erroredFields.push('representativeNameLength');
    }

    return erroredFields;
  }

  onClickContinue() {
    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.showValidationErrors(erroredFields);

      return;
    }

    let representativeName, representativeType;

    // Send updates only if neither VBMS nor VACOLS info is correct
    if (this.props.poaCorrectLocation === Constants.poaCorrectLocation.NONE) {
      representativeType = this.props.representativeType;
      if (this.props.representativeType === Constants.representativeTypes.ORGANIZATION) {
        if (this.props.organizationName === Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION) {
          representativeName = this.props.representativeName;
        } else {
          representativeName = this.props.organizationName;
        }
      }
    }

    this.props.certificationUpdateStart({
      representativeType,
      representativeName,
      poaMatches: this.props.poaMatches,
      poaCorrectLocation: this.props.poaCorrectLocation,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  static getDisplayText(value) {
    const hash = {};

    representativeTypeOptions.map((item) =>
      hash[item.value] = item.displayText);

    return hash[value];
  }

  isFieldErrored(fieldName) {
    return this.props.erroredFields && this.props.erroredFields.includes(fieldName);
  }

  calculateErrorMessage() {
    if (this.isFieldErrored('representativeName')) {
      return ERRORS.representativeName;
    } else if (this.isFieldErrored('representativeNameLength')) {
      return ERRORS.representativeNameLength;
    }

    return null;
  }

  componentDidUpdate () {
    if (this.props.scrollToError && this.props.erroredFields) {
      ValidatorsUtil.scrollToAndFocusFirstError();
      // This sets scrollToError to false so that users can edit other fields
      // without being redirected back to the first errored field.
      this.props.showValidationErrors(this.props.erroredFields, false);
    }
  }

  /* eslint max-statements: ["error", 14]*/
  render() {
    const {
      poaMatches,
      changePoaMatches,
      poaCorrectLocation,
      representativeType,
      representativeName,
      organizationName,
      changePoaCorrectLocation,
      changeOrganizationName,
      changeRepresentativeType,
      changeRepresentativeName,
      bgsRepresentativeType,
      bgsRepresentativeName,
      bgsPoaAddressFound,
      vacolsRepresentativeType,
      vacolsRepresentativeName,
      loading,
      serverError,
      updateSucceeded,
      match,
      certificationStatus
    } = this.props;

    if (!certificationStatus.includes('started')) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/check_documents`} />;
    }

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`} push />;
    }

    if (serverError) {
      return <Redirect
        to="/certifications/error" />;
    }

    let appellantInfoColumns = [
      {
        header: <h3>From VBMS</h3>,
        valueName: 'vbms'
      },
      {
        header: <h3>From VACOLS</h3>,
        valueName: 'vacols'
      }
    ];

    let appellantInfoRowObjects = [
      {
        vbms: bgsRepresentativeName || 'Representative name not found',
        vacols: vacolsRepresentativeName || 'Representative name not found'
      },
      {
        vbms: bgsRepresentativeType || 'Representative type not found',
        vacols: vacolsRepresentativeType || 'Representative type not found'
      }
    ];

    const representativeTypeMessage =
        <p>Caseflow will update the representative type in VACOLS.</p>;

    const unlistedServiceMessage =
        <p>Caseflow will update the representative type and name in VACOLS.</p>;

    return <div>
      <Header />
      <CertificationProgressBar />
      <div className="cf-app-segment cf-app-segment--alt">
        <h2>Confirm Case Details</h2>

        <div>
          {`Review information about the appellant's
              representative from VBMS and VACOLS.`}
        </div>

        <Table
          className="cf-borderless-rows"
          columns={appellantInfoColumns}
          rowObjects={appellantInfoRowObjects}
          summary="Appellant Information"
          slowReRendersAreOk
        />

        <div className="cf-help-divider"></div>

        <RadioField
          name="Does the representative information from VBMS and VACOLS match?"
          required
          options={poaMatchesOptions}
          value={poaMatches}
          errorMessage={this.isFieldErrored('poaMatches') ? ERRORS.poaMatches : null}
          onChange={changePoaMatches}
        />

        {
          poaMatches === Constants.poaMatches.NO_MATCH &&
            <RadioField
              name="Which information source shows the correct representative for this appeal?"
              options={poaCorrectLocationOptions}
              value={poaCorrectLocation}
              onChange={changePoaCorrectLocation}
              errorMessage={this.isFieldErrored('poaCorrectLocation') ? ERRORS.poaCorrectLocation : null}
              required
            />
        }

        {
          poaCorrectLocation === Constants.poaCorrectLocation.NONE &&
            <RadioField
              name="What type of representative did the appellant request for this appeal?"
              options={representativeTypeOptions}
              value={representativeType}
              onChange={changeRepresentativeType}
              errorMessage={this.isFieldErrored('representativeType') ? ERRORS.representativeType : null}
              required
            />
        }

        {
          (poaCorrectLocation === Constants.poaCorrectLocation.NONE &&
              representativeType === Constants.representativeTypes.ORGANIZATION) &&
            <Dropdown
              name="Service organization name"
              options={organizationNamesOptions}
              value={organizationName}
              defaultText="Select an organization"
              onChange={changeOrganizationName}
              errorMessage={this.isFieldErrored('organizationName') ? ERRORS.organizationName : null}
              required
            />
        }
        {
          organizationName === Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION &&
            <TextField
              name="Enter the service organization's name:"
              value={representativeName}
              errorMessage={this.calculateErrorMessage()}
              required
              onChange={changeRepresentativeName} />
        }

        {
          poaCorrectLocation === Constants.poaCorrectLocation.VACOLS &&
            'Great! Caseflow will keep the representative information as it exists now in VACOLS.'
        }
        {
          poaCorrectLocation === Constants.poaCorrectLocation.VBMS &&
            bgsPoaAddressFound === true &&
            'Great! Caseflow will update the representative name, type, and address ' +
              'in VACOLS with information from VBMS.'
        }
        {
          poaCorrectLocation === Constants.poaCorrectLocation.VBMS &&
            bgsPoaAddressFound === false &&
            'Caseflow will update the representative type in VACOLS with information from VBMS.'
        }
        {
          (representativeType === Constants.representativeTypes.ATTORNEY ||
              representativeType === Constants.representativeTypes.AGENT ||
              representativeType === Constants.representativeTypes.OTHER) &&
            representativeTypeMessage
        }
        {
          organizationName === Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION &&
            unlistedServiceMessage
        }
        {
          // TODO: change this message when we can fetch addresses.
          (organizationName && organizationName !== Constants.organizationNames.UNLISTED_SERVICE_ORGANIZATION) &&
            'Great! Caseflow will update the representative type and name information for the selected service ' +
            'organization in VACOLS.'
        }

      </div>

      <Footer
        loading={loading}
        onClickContinue={this.onClickContinue.bind(this)}
      />
    </div>;
  }
}

ConfirmCaseDetails.propTypes = {
  representativeType: PropTypes.string,
  changeRepresentativeType: PropTypes.func,
  representativeName: PropTypes.string,
  changeRepresentativeName: PropTypes.func,
  poaMatches: PropTypes.string,
  poaCorrectLocation: PropTypes.string,
  changePoaMatches: PropTypes.func,
  changePoaCorrectLocation: PropTypes.func,
  otherRepresentativeType: PropTypes.string,
  changeOtherRepresentativeType: PropTypes.func,
  erroredFields: PropTypes.array,
  scrollToError: PropTypes.bool,
  match: PropTypes.object.isRequired,
  certificationStatus: PropTypes.string,
  updateProgressBar: PropTypes.func,
  showValidationErrors: PropTypes.func,
  resetState: PropTypes.func,
  changeOrganizationName: PropTypes.func,
  certificationUpdateStart: PropTypes.func,
  organizationName: PropTypes.string,
  bgsRepresentativeType: PropTypes.string,
  bgsRepresentativeName: PropTypes.string,
  bgsPoaAddressFound: PropTypes.bool,
  vacolsRepresentativeType: PropTypes.string,
  vacolsRepresentativeName: PropTypes.string,
  loading: PropTypes.bool,
  serverError: PropTypes.bool,
  updateSucceeded: PropTypes.bool
};

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch(actions.updateProgressBar());
  },

  showValidationErrors: (erroredFields, scrollToError = true) => {
    dispatch(certificationActions.showValidationErrors(erroredFields, scrollToError));
  },

  resetState: () => dispatch(certificationActions.resetState()),

  changeRepresentativeName: (name) => dispatch(actions.changeRepresentativeName(name)),

  changeOrganizationName: (name) => dispatch(actions.changeOrganizationName(name)),

  changeRepresentativeType: (type) => dispatch(actions.changeRepresentativeType(type)),

  changeOtherRepresentativeType: (other) => {
    dispatch(actions.changeOtherRepresentativeType(other));
  },

  changePoaMatches: (poaMatches) => dispatch(actions.changePoaMatches(poaMatches)),
  changePoaCorrectLocation: (poaCorrectLocation) => dispatch(actions.changePoaCorrectLocation(poaCorrectLocation)),

  certificationUpdateStart: (props) => {
    dispatch(actions.certificationUpdateStart(props, dispatch));
  }
});

const mapStateToProps = (state) => ({
  updateSucceeded: state.updateSucceeded,
  serverError: state.serverError,
  representativeType: state.representativeType,
  representativeName: state.representativeName,
  organizationName: state.organizationName,
  bgsRepresentativeType: state.bgsRepresentativeType,
  bgsRepresentativeName: state.bgsRepresentativeName,
  bgsPoaAddressFound: state.bgsPoaAddressFound,
  vacolsRepresentativeType: state.vacolsRepresentativeType,
  vacolsRepresentativeName: state.vacolsRepresentativeName,
  otherRepresentativeType: state.otherRepresentativeType,
  poaMatches: state.poaMatches,
  poaCorrectLocation: state.poaCorrectLocation,
  continueClicked: state.continueClicked,
  erroredFields: state.erroredFields,
  scrollToError: state.scrollToError,
  loading: state.loading,
  certificationStatus: state.certificationStatus
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ConfirmCaseDetails);
