/* eslint-disable no-nested-ternary */
import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import { detailListStyling, getDetailField } from './Detail';
import { DateString } from '../util/DateUtil';
import BareList from '../components/BareList';
import COPY from '../../COPY';
import CAVC_REMAND_SUBTYPE_NAMES from '../../constants/CAVC_REMAND_SUBTYPE_NAMES';
import CAVC_DECISION_TYPES from '../../constants/CAVC_DECISION_TYPES';

const CavcDetail = (props) => {
  const {
    cavc_docket_number: docketNumber,
    represented_by_attorney: hasAttorney,
    cavc_judge_full_name: judgeName,
    cavc_decision_type: procedure,
    remand_subtype: type,
    decision_date: decisionDate,
    judgement_date: judgementDate,
    mandate_date: mandateDate,
    federal_circuit: federalCircuit,
    instructions: instructionText
  } = props;

  const details = [];

  if (docketNumber) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_DOCKET_NUMBER,
      value: docketNumber
    });
  }

  if (hasAttorney === true) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_ATTORNEY,
      value: 'Yes'
    });
  } else if (hasAttorney === false) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_ATTORNEY,
      value: 'No'
    });
  }

  if (judgeName) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_JUDGE,
      value: judgeName
    });
  }

  if (procedure) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_PROCEDURE,
      value: _.startCase(procedure)
    });
  }

  if (type && procedure === CAVC_DECISION_TYPES.remand) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_TYPE,
      value: CAVC_REMAND_SUBTYPE_NAMES[type]
    });
  }

  if (decisionDate) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_DECISION_DATE,
      value: <DateString date={decisionDate} inputFormat="YYYY-MM-DD" dateFormat="M/D/YYYY" />
    });
  }

  if (judgementDate) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_JUDGEMENT_DATE,
      value: <DateString date={judgementDate} inputFormat="YYYY-MM-DD" dateFormat="M/D/YYYY" />
    });
  }

  if (mandateDate) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_MANDATE_DATE,
      value: <DateString date={mandateDate} inputFormat="YYYY-MM-DD" dateFormat="M/D/YYYY" />
    });
  }

  if (federalCircuit !== null) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_FEDERAL_CIRCUIT,
      value: (federalCircuit === true) ? 'Yes' : 'No'
    });
  }

  if (instructionText) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_REMAND_INSTRUCTIONS,
      value: instructionText
    });
  }

  return (
    <>
      <ul {...detailListStyling}>
        <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
      </ul>
    </>
  );
};

CavcDetail.propTypes = {
  cavc_docket_number: PropTypes.string.isRequired,
  represented_by_attorney: PropTypes.bool.isRequired,
  cavc_judge_full_name: PropTypes.string.isRequired,
  cavc_decision_type: PropTypes.string.isRequired,
  remand_subtype: PropTypes.string,
  decision_date: PropTypes.string.isRequired,
  judgement_date: PropTypes.string,
  mandate_date: PropTypes.string,
  federal_circuit: PropTypes.bool,
  instructions: PropTypes.string.isRequired
};

export default CavcDetail;
