import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as actions from './actions/ConfirmCaseDetails';
import * as certificationActions from './actions/Certification';
import { Redirect } from 'react-router-dom';

import ValidatorsUtil from '../util/ValidatorsUtil';
import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import Table from '../components/Table';
import Footer from './Footer';

const representativeTypeOptions = [
  {
    displayText: 'Attorney',
    value: Constants.representativeTypes.ATTORNEY
  },
  {
    displayText: 'Agent',
    value: Constants.representativeTypes.AGENT
  },
  {
    displayText: 'Organization',
    value: Constants.representativeTypes.ORGANIZATION
  },
  {
    displayText: 'None',
    value: Constants.representativeTypes.NONE
  },
  {
    displayText: 'Other',
    value: Constants.representativeTypes.OTHER
  }
];

// TODO: We should give each question a constant name.
const ERRORS = {
  representativeType: 'Please enter the representative type.',
  representativeName: 'Please enter the representative name.',
  otherRepresentativeType: 'Please enter the other representative type.'
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

  representativeTypeIsNone() {
    return this.props.representativeType === Constants.representativeTypes.NONE;
  }

  representativeTypeIsOther() {
    return this.props.representativeType === Constants.representativeTypes.OTHER;
  }

  getValidationErrors() {
    // TODO: consider breaking this and all validation out into separate
    // modules.
    let {
      representativeName,
      representativeType,
      otherRepresentativeType
    } = this.props;

    const erroredFields = [];

    // We always need a representative type.
    if (ValidatorsUtil.requiredValidator(representativeType)) {
      erroredFields.push('representativeType');
    }

    // Unless the type of representative is "None",
    // we need a representative name.
    if (ValidatorsUtil.requiredValidator(representativeName) && !this.representativeTypeIsNone()) {
      erroredFields.push('representativeName');
    }

    // If the representative type is "Other",
    // fill out the representative type.
    if (this.representativeTypeIsOther() && ValidatorsUtil.requiredValidator(otherRepresentativeType)) {
      erroredFields.push('otherRepresentativeType');
    }

    return erroredFields;
  }

  onClickContinue() {

    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.showValidationErrors(erroredFields);

      return;
    }

    this.props.certificationUpdateStart({
      representativeType: this.props.representativeType,
      otherRepresentativeType: this.props.otherRepresentativeType,
      representativeName: this.props.representativeName,
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
      representativeType,
      changeRepresentativeType,
      bgsRepresentativeType,
      bgsRepresentativeName,
      vacolsRepresentativeType,
      vacolsRepresentativeName,
      representativeName,
      changeRepresentativeName,
      otherRepresentativeType,
      changeOtherRepresentativeType,
      loading,
      serverError,
      updateSucceeded,
      match,
      certificationStatus
    } = this.props;

    if(!certificationStatus.includes('started')) {
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

    const shouldShowOtherTypeField =
      representativeType === Constants.representativeTypes.OTHER;

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
            name="Representative type"
            options={representativeTypeOptions}
            value={representativeType}
            onChange={changeRepresentativeType}
            errorMessage={this.isFieldErrored('representativeType') ? ERRORS.representativeType : null}
            required={true}
          />

          {
            shouldShowOtherTypeField &&
            <TextField
              name={'Specify other representative type'}
              value={otherRepresentativeType}
              onChange={changeOtherRepresentativeType}
              errorMessage={this.isFieldErrored('otherRepresentativeType') ? ERRORS.otherRepresentativeType : null}
              required={true}
            />
          }

          <TextField
            name={'Representative name'}
            value={representativeName}
            onChange={changeRepresentativeName}
            errorMessage={this.isFieldErrored('representativeName') ? ERRORS.representativeName : null}
            required={true}
          />

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
  vacolsRepresentativeType: state.vacolsRepresentativeType,
  vacolsRepresentativeName: state.vacolsRepresentativeName,
  otherRepresentativeType: state.otherRepresentativeType,
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
