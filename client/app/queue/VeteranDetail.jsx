import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { get } from 'lodash';

import { DateString } from '../util/DateUtil';
import { appealWithDetailSelector } from './selectors';
import { detailListStyling, getDetailField } from './Detail';
import { getAppealValue } from './QueueActions';
import Address from './components/Address';
import BareList from '../components/BareList';
import COPY from '../../COPY';

/**
 * A component to display various details about the veteran including name, gender, date of birth, date of death,
 * address and email.
 */
export const VeteranDetail = ({ appealId, stateOnly }) => {
  const dispatch = useDispatch();

  const loadingVeteranInfo = useSelector((state) => get(state.queue.loadingAppealDetail[appealId], 'veteranInfo'));
  const appeal = useSelector((state) => appealWithDetailSelector(state, { appealId }));
  const veteranInfo = appeal?.veteranInfo;

  useEffect(() => {
    if (!veteranInfo && !loadingVeteranInfo) {
      dispatch(getAppealValue(appealId, 'veteran', 'veteranInfo'));
    }
  });

  if (loadingVeteranInfo?.error) {
    debugger;
    return <>{COPY.CASE_DETAILS_UNABLE_TO_LOAD}</>;
  } else if (loadingVeteranInfo?.loading || !appeal) {
    return <>{COPY.CASE_DETAILS_LOADING}</>;
  }

  if (veteranInfo) {
    const {
      veteran: {
        address,
        full_name: fullName,
        gender,
        date_of_birth: dob,
        date_of_death: dod,
        email_address: email
      }
    } = veteranInfo;

    if (stateOnly) {
      return <>{address?.state}</>;
    }

    const details = [{
      label: 'Name',
      value: fullName
    }];

    const genderValue = gender === 'F' ? COPY.CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE :
      COPY.CASE_DETAILS_GENDER_FIELD_VALUE_MALE;

    if (genderValue) {
      details.push({
        label: COPY.CASE_DETAILS_GENDER_FIELD_LABEL,
        value: genderValue
      });
    }

    if (dob) {
      details.push({
        label: 'Date of birth',
        value: <DateString date={dob} inputFormat="MM/DD/YYYY" dateFormat="M/D/YYYY" />
      });
    }

    if (dod) {
      details.push({
        label: 'Date of death',
        value: <DateString date={dod} inputFormat="MM/DD/YYYY" dateFormat="M/D/YYYY" />
      });
    }

    if (address) {
      details.push({
        label: 'Mailing Address',
        value: <Address address={address} />
      });
    }

    if (email) {
      details.push({
        label: 'Email Address',
        value: email
      });
    }

    return (
      <ul {...detailListStyling}>
        <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
        <p><em>{COPY.CASE_DETAILS_VETERAN_ADDRESS_SOURCE}</em></p>
      </ul>
    );
  }

  return null;
};

VeteranDetail.propTypes = {

  /**
   * The veteran appeal's external id, used to request veteran information from the back end
   */
  appealId: PropTypes.string.isRequired,

  /**
   * Whether or not to display only the veteran's state of residence
   */
  stateOnly: PropTypes.bool,
};

export default VeteranDetail;
