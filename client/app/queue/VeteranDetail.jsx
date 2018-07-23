import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import { boldText } from './constants';
import { DateString } from '../util/DateUtil';

const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});
const addressIndentStyling = (secondLine) => css({
  marginLeft: secondLine ? '7.5em' : 0
});

export default class VeteranDetail extends React.PureComponent {
  getAppealAttr = (attr) => _.get(this.props.appeal.attributes, attr);

  formatAddress = (addressFieldName) => {
    const {
      address_line_1: addressLine1,
      address_line_2: addressLine2,
      city,
      state,
      zip,
      country
    } = this.getAppealAttr(addressFieldName);
    const streetAddress = addressLine2 ? `${addressLine1} ${addressLine2}` : addressLine1;

    return <React.Fragment>
      {streetAddress && <React.Fragment><span>{streetAddress},</span><br /></React.Fragment>}
      <span {...addressIndentStyling(streetAddress)}>{city}, {state} {zip} {country === 'USA' ? '' : country}</span>
    </React.Fragment>;
  };

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
        value: this.formatAddress(addressField)
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
      nameField: 'veteran_full_name',
      genderField: 'veteran_gender',
      dobField: 'veteran_date_of_birth',
      addressField: 'appellant_address',
      regionalOfficeField: 'regional_office'
    })}
  </ul>;
}

VeteranDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
