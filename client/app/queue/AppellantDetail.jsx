import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { boldText } from './constants';
import { detailListStyling } from './Detail';
import Address from './components/Address';
import BareList from '../components/BareList';
import COPY from '../../COPY';

export default class AppellantDetail extends React.PureComponent {
  getAppealAttr = (attr) => _.get(this.props.appeal, attr);

  getGenderValue = (genderFieldName) => this.getAppealAttr(genderFieldName) === 'F' ?
    COPY.CASE_DETAILS_GENDER_FIELD_VALUE_FEMALE :
    COPY.CASE_DETAILS_GENDER_FIELD_VALUE_MALE;

  getDetails = ({ nameField, addressField, relationField }) => {
    const details = [{
      label: 'Name',
      value: this.getAppealAttr(nameField)
    }];

    if (relationField && this.getAppealAttr(relationField)) {
      details.push({
        label: 'Relation to Veteran',
        value: this.getAppealAttr(relationField)
      });
    }
    if (addressField && this.getAppealAttr(addressField)) {
      details.push({
        label: 'Mailing Address',
        value: <Address address={this.getAppealAttr(addressField)} />
      });
    }

    const getDetailField = ({ label, value }) => () => <React.Fragment>
      <span {...boldText}>{label}:</span> {value}
    </React.Fragment>;

    return <BareList ListElementComponent="ul" items={details.map(getDetailField)} />;
  };

  render = () => <ul {...detailListStyling}>
    {this.getDetails({
      nameField: 'appellantFullName',
      addressField: 'appellantAddress',
      relationField: 'appellantRelationship'
    })}
  </ul>;
}

AppellantDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
