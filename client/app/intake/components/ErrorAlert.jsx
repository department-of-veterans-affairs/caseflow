
import React, { Fragment } from 'react';
import Alert from '../../components/Alert';
import BareList from '../../components/BareList';
import _ from 'lodash';
import PropTypes from 'prop-types';
import { ERROR_ADDRESS_LINE_INVALID_CHARACTERS,
  ERROR_CITY_INVALID_CHARACTERS,
  ERROR_ADDRESS_TOO_LONG, INTAKE_VETERAN_DATE_OF_BIRTH_ERROR,
  INTAKE_VETERAN_NAME_SUFFIX_ERROR,
  ERROR_INVALID_ZIP_CODE,
  INTAKE_VETERAN_PAY_GRADE_INVALID } from '../../../COPY';
import { css } from 'glamor';

const missingFieldsMessage = (fields) => <p>
  Please fill in the following fields in the Veteran's profile in VBMS or the corporate database,
  then retry establishing the EP in Caseflow: {fields}.
</p>;

const addressTips = [
  () => <Fragment>Do: move the last words of the street address down to an another street address field</Fragment>,
  () => <Fragment>Do: abbreviate to St. Ave. Rd. Blvd. Dr. Ter. Pl. Ct.</Fragment>,
  () => <Fragment>Don't: edit street names or numbers</Fragment>,
  () => <Fragment>Don't: use invalid characters such as *%$Ð</Fragment>
];

const veteranAddressTips = <Fragment>
  <p {...css({ marginTop: '10px',
    marginBottom: '10px' })}>Tips:</p>
  <BareList items={addressTips} ListElementComponent="ul" />
</Fragment>;

export const invalidVeteranCharacters = (searchErrorData) => {
  let errorMessage;

  if (searchErrorData.veteranAddressInvalidFields) {
    errorMessage = <Fragment>
      <p>{ERROR_ADDRESS_LINE_INVALID_CHARACTERS}</p>
      <span>{veteranAddressTips}</span>
    </Fragment>;
  } else if (searchErrorData.veteranCityInvalidFields) {
    errorMessage = <Fragment>
      <p>{ERROR_CITY_INVALID_CHARACTERS}</p>
      <span>{veteranAddressTips}</span>
    </Fragment>;
  } else if (searchErrorData.veteranAddressTooLong) {
    errorMessage = <Fragment>
      <p>{ERROR_ADDRESS_TOO_LONG}</p>
      <span>{veteranAddressTips}</span>
    </Fragment>;
  } else if (searchErrorData.veteranDateOfBirthInvalid) {
    errorMessage = <Fragment>
      <p>{INTAKE_VETERAN_DATE_OF_BIRTH_ERROR}</p>
    </Fragment>;
  } else if (searchErrorData.veteranNameSuffixInvalid) {
    errorMessage = <Fragment>
      <p>{INTAKE_VETERAN_NAME_SUFFIX_ERROR}</p>
    </Fragment>;
  } else if (searchErrorData.veteranZipCodeInvalid) {
    errorMessage = <Fragment>
      <p>{ERROR_INVALID_ZIP_CODE}</p>
    </Fragment>;
  } else if (searchErrorData.veteranPayGradeInvalid) {
    errorMessage = <Fragment>
      <p>{INTAKE_VETERAN_PAY_GRADE_INVALID}</p>
    </Fragment>;
  }

  return errorMessage;
};

export const invalidVeteranInstructions = (searchErrorData) => {
  if (searchErrorData) {
    return <Fragment>
      { (_.get(searchErrorData.veteranMissingFields, 'length', 0) > 0) &&
        missingFieldsMessage(searchErrorData.veteranMissingFields) }
      { invalidVeteranCharacters(searchErrorData) }
    </Fragment>;
  }
};

export default class ErrorAlert extends React.PureComponent {
  render() {
    const errorObject = {
      duplicate_ep: {
        title: 'An EP for this claim already exists in VBMS',
        body: `An EP ${this.props.errorData} for this Veteran's claim was created` +
              ' outside Caseflow. Please tell your manager as soon as possible so they can resolve the issue.'
      },
      no_changes: {
        title: 'No changes were selected',
        body: 'Please select at least one change and try again.'
      },
      previous_update_not_done_processing: {
        title: 'Previous update not yet done processing',
        body: (
          <Fragment>
            A previously submitted update has not yet finished processing. Please wait a few minutes and try again.
            <br /><br />
            If it's still not working after that, please contact the Caseflow team
            via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
            via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
          </Fragment>
        )
      },
      default: {
        title: 'Something went wrong',
        body: (
          <Fragment>
            <div>Error code {this.props.errorUUID}</div>
            <div>
              Please try again. If the problem persists, please contact the Caseflow team
              via the VA Enterprise Service Desk at 855-673-4357 or by creating a ticket
              via <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer">YourIT</a>.
            </div>
          </Fragment>
        )
      },
      veteran_not_valid: {
        title: 'Check the Veteran\'s profile for invalid information',
        body: invalidVeteranInstructions(this.props.errorData)
      },
      unable_to_edit_ep: {
        body: (
          <Fragment>
           We were unable to edit the claim label. Please try again and if this error persists,
            <a href="https://yourit.va.gov" target="_blank" rel="noopener noreferrer"> submit a YourIT ticket</a>.
          </Fragment>
        )
      }
    }[this.props.errorCode || 'default'];

    return <Alert title={errorObject.title} type="error" lowerMargin>
      {errorObject.body}
    </Alert>;
  }
}

ErrorAlert.propTypes = {
  errorData: PropTypes.object,
  errorUUID: PropTypes.object,
  errorCode: PropTypes.string
};
