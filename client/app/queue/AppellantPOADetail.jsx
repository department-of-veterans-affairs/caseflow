import PropTypes from 'prop-types';
import React from 'react';

import { detailListStyling, getDetailField } from './Detail';
import Address from './components/Address';
import BareList from '../components/BareList';

/**
 * A component to display various details about the appeal's appellant including name, address and their relation to the
 * veteran
 */
export const AppellantPOADetail = ({ appeal }) => {
  const {
    appellantAddress,
    appellantFullName,
    appellantRelationship
  } = appeal;

  const details = [{
    label: 'Name',
    value: appellantFullName
  }];

  if (appellantAddress) {
    details.push({
      label: 'Mailing Address',
      value: <Address address={appellantAddress} />
    });
  }

  if (appellantRelationship) {
    details.push({
      label: 'Phone Number',
      value: appellantRelationship
    });
  }

  return (
    <ul {...detailListStyling}>
      <BareList ListElementComponent="ul" items={details.map(getDetailField)} />
    </ul>
  );
};

AppellantPOADetail.propTypes = {

  /**
   * Appeal object that contains information abbout the appellant including name, address, and their relation to the
   * veteran
   */
  appeal: PropTypes.shape({
    appellantAddress: PropTypes.object,
    appellantFullName: PropTypes.string,
    appellantRelationship: PropTypes.string
  }).isRequired
};

export default AppellantPOADetail;
