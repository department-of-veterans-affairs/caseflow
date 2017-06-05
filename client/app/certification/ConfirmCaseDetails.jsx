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

// TODO: We should give each question a constant name.
const ERRORS = {
  poaMatches: 'Please select yes or no.',
  poaCorrectLocation: 'Please select an option.'
};

/*
 * Confirm Case Details
 *
 * This page will display information from BGS
 * about the appellant's representation for the appeal
 * and confirm it.
 *
 * On the backend, we'll then update that information in VACOLS
 * if necessary. This was created since power of attorney
 * information in VACOLS is very often out of date, which can
 * in case delays -- attorneys can't access the appeal information
 * if they're not noted as being the appellant's representative
 *
 */

export class ConfirmCaseDetails extends React.Component {
  // TODO: updating state in ComponentWillMount is
  // sometimes thought of as an anti-pattern.
  // is there a better way to do this?
  componentWillMount() {
    this.props.updateProgressBar();
  }

  componentWillUnmount() {
    this.props.resetState();
  }

  getValidationErrors() {
    // TODO: consider breaking this and all validation out into separate
    // modules.
    let {
      poaMatches,
      poaCorrectLocation
    } = this.props;

    const erroredFields = [];

    if (ValidatorsUtil.requiredValidator(poaMatches)) {
      erroredFields.push('poaMatches');
    }

    if (poaMatches === Constants.poaMatches.NO_MATCH && ValidatorsUtil.requiredValidator(poaCorrectLocation)) {
      erroredFields.push('poaCorrectLocation');
    }

    return erroredFields;
  }

  onClickContinue() {

    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.showValidationErrors(erroredFields);

      return;
    }

    let representativeName = this.props.vacolsRepresentativeName;
    let representativeType = this.props.vacolsRepresentativeType;

    if (this.props.poaCorrectLocation === Constants.poaCorrectLocation.VBMS &&
      this.props.poaMatches === Constants.poaMatches.NO_MATCH) {
      representativeName = this.props.bgsRepresentativeName;
      representativeType = this.props.bgsRepresentativeType;
    }

    this.props.certificationUpdateStart({
      representativeType,
      representativeName,
      poaMatches: this.props.poaMatches,
      poaCorrectLocation: this.props.poaCorrectLocation,
      vacolsId: this.props.match.params.vacols_id
    });
  }

  isFieldErrored(fieldName) {
    return this.props.erroredFields && this.props.erroredFields.includes(fieldName);
  }

  componentDidUpdate () {
    if (this.props.scrollToError && this.props.erroredFields) {
      ValidatorsUtil.scrollToAndFocusFirstError();
      // This sets scrollToError to false so that users can edit other fields
      // without being redirected back to the first errored field.
      this.props.showValidationErrors(this.props.erroredFields, false);
    }
  }

  render() {
    let {
      poaMatches,
      changePoaMatches,
      poaCorrectLocation,
      changePoaCorrectLocation,
      bgsRepresentativeType,
      bgsRepresentativeName,
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
        to={`/certifications/${match.params.vacols_id}/check_documents`}/>;
    }

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`}/>;
    }

    if (serverError) {
      return <Redirect
        to={'/certifications/error'}/>;
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
        vbms: bgsRepresentativeName,
        vacols: vacolsRepresentativeName
      },
      {
        vbms: bgsRepresentativeType,
        vacols: vacolsRepresentativeType
      }
    ];

    return <div>
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
          />

          <div className="cf-help-divider"></div>

          <RadioField
            name="Does the representative information from VBMS and VACOLS match?"
            required={true}
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
              required={true}
            />
          }

          {
            poaCorrectLocation === Constants.poaCorrectLocation.VACOLS &&
            'Great! Caseflow will keep the representative information as it exists now in VACOLS.'
          }
          {
            poaCorrectLocation === Constants.poaCorrectLocation.VBMS &&
            'Great! Caseflow will update the representative name, type, and address ' +
              'in VACOLS with information from VBMS.'
          }
          {
            poaCorrectLocation === Constants.poaCorrectLocation.NONE &&
            'Please go to VACOLS and manually enter the correct representative information.'
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
  certificationStatus: PropTypes.string
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
