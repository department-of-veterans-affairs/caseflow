import PropTypes from 'prop-types';
import React from 'react';

import { detailListStyling, getDetailField } from './Detail';
import Address from './components/Address';
import BareList from '../components/BareList';
import { DateString } from 'app/util/DateUtil';
import Alert from '../components/Alert';
import { CASE_TIMELINE_APPELLANT_IS_A_SUBSTITUTE, CASE_TIMELINE_APPELLANT_SUBSTITUTION } from 'app/../COPY';

/**
 * A component to display various details about the appeal's appellant including name, address and their relation to the
 * veteran
 */
export const AppellantDetail = ({ appeal, substitutionDate }) => {
  const {
    appellantAddress,
    appellantFullName,
    appellantRelationship
  } = appeal;

  const details = [{
    label: 'Name',
    value: appellantFullName
  }];

  if (appellantRelationship) {
    details.push({
      label: 'Relation to Veteran',
      value: appellantRelationship
    });
  }

  if (appellantAddress) {
    details.push({
      label: 'Mailing Address',
      value: <Address address={appellantAddress} />
    });
  }

  if (substitutionDate) {
    details.push({
      label: CASE_TIMELINE_APPELLANT_SUBSTITUTION,
      value: <DateString date={substitutionDate} inputFormat="YYYY-MM-DD" dateFormat="M/D/YYYY" />
    });
  }

  return (
    <React.Fragment>
      <ul {...detailListStyling}>
        <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
      </ul>
      {substitutionDate && <Alert
        message={CASE_TIMELINE_APPELLANT_IS_A_SUBSTITUTE}
        type="info"
      />}
    </React.Fragment>
  );
};

AppellantDetail.propTypes = {

  /**
   * Appeal object that contains information about the appellant including name, address, and their relation to the
   * veteran
   */
  appeal: PropTypes.shape({
    appellantAddress: PropTypes.object,
    appellantFullName: PropTypes.string,
    appellantRelationship: PropTypes.string
  }).isRequired,

  substitutionDate: PropTypes.string,
};

export default AppellantDetail;
