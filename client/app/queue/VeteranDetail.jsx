import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';

import { boldText } from './constants';

export default class VeteranDetail extends React.PureComponent {
  getStyling = () => css({
    '> .veteran-summary-ul': {
      paddingLeft: 0,
      listStyle: 'none'
    }
  });

  getAppealAttr = (attr) => _.get(this.props.appeal.attributes, attr);

  formatAddress = () => {
    const {
      address_line_1: addressLine1,
      address_line_2: addressLine2,
      city,
      state,
      zip,
      country
    } = this.getAppealAttr('appellant_address');
    const streetAddress = `${addressLine1}${addressLine2 || ''}`;

    return `${streetAddress}, ${city} ${state}, ${zip} ${country === 'USA' ? '' : country}`;
  }

  getListElements = () => [{
    label: 'Name',
    valueFunction: () => this.getAppealAttr('veteran_full_name')
  }, {
    label: 'Gender',
    valueFunction: () => this.getAppealAttr('veteran_gender') === 'F' ? 'Female' : 'Male'
  }, {
    label: 'Date of birth',
    valueFunction: () => moment(this.getAppealAttr('veteran_date_of_birth')).format('M/D/YYYY')
  }, {
    label: 'Mailing address',
    valueFunction: () => this.formatAddress()
  }].map(({ label, valueFunction }, idx) => <li key={`veteran-summary-${idx}`}>
    <span {...boldText}>{label}:</span> {valueFunction()}
  </li>);

  render = () => <div {...this.getStyling()}>
    <h2>Veteran Details</h2>
    {/* <span>The veteran is the appellant</span>*/}
    <ul className="veteran-summary-ul">
      {this.getListElements()}
    </ul>
  </div>
}

VeteranDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
