import React, { PropTypes } from 'react';
import { connect } from 'react-redux';
import * as Constants from './constants/constants';
import * as actions from './actions/ConfirmCaseDetails';
import * as certificationActions from './actions/Certification';
import { Redirect } from 'react-router-dom';

import ValidatorsUtil from '../util/ValidatorsUtil';
import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
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

const REP_NAME_ID = 'Representative name';
const REP_TYPE_ID = 'Representative-type_ATTORNEY';
const OTHER_REP_TYPE_ID = 'Specify other representative type';
const REP_NAME_ERROR = 'Please enter the representative name.';
const REP_TYPE_ERROR = 'Please enter the representative type.';
const OTHER_REP_TYPE_ERROR = 'Please enter the other representative type.';

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
      erroredFields.push(REP_TYPE_ID);
    }

    // Unless the type of representative is "None",
    // we need a representative name.
    if (ValidatorsUtil.requiredValidator(representativeName) && !this.representativeTypeIsNone()) {
      erroredFields.push(REP_NAME_ID);
    }

    // If the representative type is "Other",
    // fill out the representative type.
    if (this.representativeTypeIsOther() && ValidatorsUtil.requiredValidator(otherRepresentativeType)) {
      erroredFields.push(OTHER_REP_TYPE_ID);
    }

    return erroredFields;
  }

  onClickContinue() {

    const erroredFields = this.getValidationErrors();

    if (erroredFields.length) {
      this.props.changeErroredFields(erroredFields);
      window.scrollBy(0, document.getElementById(erroredFields[0]).getBoundingClientRect().top - 30);

      return;
    }

    this.props.changeErroredFields(null);

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

  render() {
    let {
      representativeType,
      changeRepresentativeType,
      representativeName,
      changeRepresentativeName,
      otherRepresentativeType,
      changeOtherRepresentativeType,
      loading,
      updateFailed,
      updateSucceeded,
      match
    } = this.props;

    if (updateSucceeded) {
      return <Redirect
        to={`/certifications/${match.params.vacols_id}/confirm_hearing`}/>;
    }

    if (updateFailed) {
      // TODO: add real error handling and validated error states etc.
      return <div>500 500 error error</div>;
    }

    const shouldShowOtherTypeField =
      representativeType === Constants.representativeTypes.OTHER;

    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Confirm Case Details</h2>

          <div>
            {`Review data from BGS about the appellant's
              representative and make changes if necessary.`}
          </div>

          <div className="cf-help-divider"></div>

          <RadioField
            name="Representative type"
            options={representativeTypeOptions}
            value={representativeType}
            onChange={changeRepresentativeType}
            errorMessage={(this.isFieldErrored(REP_TYPE_ID) ? REP_TYPE_ERROR : null)}
            required={true}
          />

          {
            shouldShowOtherTypeField &&
            <TextField
              name={OTHER_REP_TYPE_ID}
              value={otherRepresentativeType}
              onChange={changeOtherRepresentativeType}
              errorMessage={(this.isFieldErrored(OTHER_REP_TYPE_ID) ? OTHER_REP_TYPE_ERROR : null)}
              required={true}
            />
          }

          <TextField
            name={REP_NAME_ID}
            value={representativeName}
            onChange={changeRepresentativeName}
            errorMessage={(this.isFieldErrored(REP_NAME_ID) ? REP_NAME_ERROR : null)}
            required={true}
          />

        </div>

        <Footer
          disableContinue={false}
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
  match: PropTypes.object.isRequired
};

const mapDispatchToProps = (dispatch) => ({
  updateProgressBar: () => {
    dispatch(actions.updateProgressBar());
  },

  changeErroredFields: (erroredFields) => {
    dispatch(certificationActions.changeErroredFields(erroredFields));
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
  updateFailed: state.updateFailed,
  representativeType: state.representativeType,
  representativeName: state.representativeName,
  otherRepresentativeType: state.otherRepresentativeType,
  erroredFields: state.erroredFields,
  loading: state.loading
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(ConfirmCaseDetails);
