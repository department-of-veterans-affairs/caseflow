import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import { boldText } from './constants';
import { DateString } from '../util/DateUtil';
import Address from './components/Address';

const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});

export default class AppellantDetail extends React.PureComponent {
  getAppealAttr = (attr) => _.get(this.props.appeal, attr);

  getGenderPronoun = (genderFieldName) => this.getAppealAttr(genderFieldName) === 'F' ? 'She/Her' : 'He/His';

  getDetails = ({ nameField, genderField, dobField, addressField, relationField, regionalOfficeField }) => {
    const details = [{
      label: 'Name',
      value: this.getAppealAttr(nameField)
    }];

    if (genderField && this.getAppealAttr(genderField)) {
      details.push({
        label: 'Gender pronoun',
        value: this.getGenderPronoun(genderField)
      });
    }
    if (dobField && this.getAppealAttr(dobField)) {
      details.push({
        label: 'Date of birth',
        value: <DateString date={this.getAppealAttr(dobField)} dateFormat="M/D/YYYY" />
      });
    }
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
    if (regionalOfficeField && this.getAppealAttr(regionalOfficeField)) {
      const { city, key } = this.getAppealAttr(regionalOfficeField);

      details.push({
        label: 'Regional Office',
        value: `${city} (${key.replace('RO', '')})`
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
