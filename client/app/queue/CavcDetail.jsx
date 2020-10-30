/* eslint-disable no-nested-ternary */
import React from 'react';
import PropTypes from 'prop-types';

import { detailListStyling, getDetailField } from './Detail';
import { DateString } from '../util/DateUtil';
import BareList from '../components/BareList';
import COPY from '../../COPY';

const CavcDetail = (props) => {
  const {
    cavc_docket_number: docketNumber,
    represented_by_attorney: hasAttorney,
    cavc_judge_full_name: judgeName,
    cavc_decision_type: procedure,
    remand_subtype: type,
    decision_date: decisionDate,
    judgement_date: judgementDate,
    mandate_date: mandateDate
  } = props;

  const details = [{
    label: COPY.CASE_DETAILS_CAVC_DOCKET_NUMBER,
    value: docketNumber
  }];

  if (hasAttorney) {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_ATTORNEY,
      value: hasAttorney === true ? 'Yes' : 'No'
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
      value: procedure.charAt(0).toUpperCase() + procedure.slice(1)

    });
  }

  if (type && procedure !== 'death_dismissal' && procedure !== 'straight_reversal') {
    details.push({
      label: COPY.CASE_DETAILS_CAVC_TYPE,
      value: (type === 'jmr') ? 'Joint Motion for Remand' :
        (type === 'jmpr') ? 'Joint Motion Partial Remand' : 'Memorandum Decision on Remand'
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
  mandate_date: PropTypes.string
};

export default CavcDetail;
