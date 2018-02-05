import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import { boldText, redText } from './constants';
import { dateString } from './utils';

const appellantDetailStyling = css({
  '& ul': {
    paddingLeft: 0,
    listStyle: 'none'
  },
  '& h2': {
    marginBottom: '5px',
    '&:nth-of-type(2)': {
      marginTop: '3rem'
    }
  }
});

const addressSecondLineStyling = css({
  marginLeft: '12.5rem'
});

export default class AppellantDetail extends React.PureComponent {
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
    const streetAddress = `${addressLine1} ${addressLine2 || ''}`;

    return <React.Fragment>
      <span>{streetAddress},</span><br/>
      <span {...addressSecondLineStyling}>{city} {state}, {zip} {country === 'USA' ? '' : country}</span>
    </React.Fragment>;
  };

  getPreferredPronoun = (genderFieldName) => this.getAppealAttr(genderFieldName) === 'F' ? 'She/Her' : 'He/His';

  veteranIsAppellant = () => _.isNull(this.getAppealAttr('appellant_full_name'));

  getDetails = ({ nameField, genderField, dobField, addressField }) => {
    const details = [{
      label: 'Name',
      valueFunction: () => this.getAppealAttr(nameField)
    }];

    if (genderField) {
      details.push({
        label: 'Preferred pronoun',
        valueFunction: () => this.getPreferredPronoun(genderField)
      });
    }
    if (dobField) {
      details.push({
        label: 'Date of birth',
        valueFunction: () => dateString(this.getAppealAttr(dobField), 'M/D/YYYY')
      });
    }
    if (addressField) {
      details.push({
        label: 'Mailing Address',
        valueFunction: () => this.formatAddress(addressField)
      });
    }

    return details;
  };

  renderListElements = (elements = []) => elements.map(({ label, valueFunction }, idx) =>
    <li key={idx}>
      <span {...boldText}>{label}:</span> {valueFunction()}
    </li>);

  render = () => {
    let appellantDetails;
    let veteranDetails;

    if (this.veteranIsAppellant()) {
      appellantDetails = <React.Fragment>
        <h2>Veteran Details</h2>
        <span>The veteran is the appellant.</span>
        <ul>
          {this.renderListElements(
            this.getDetails({
              nameField: 'veteran_full_name',
              genderField: 'veteran_gender',
              dobField: 'veteran_date_of_birth'
            })
          )}
        </ul>
      </React.Fragment>;
    } else {
      appellantDetails = <React.Fragment>
        <h2>Appellant Details</h2>
        <span>The veteran is not the appellant.</span>
        <ul>
          {this.renderListElements(
            this.getDetails({ nameField: 'appellant_full_name', addressField: 'appellant_address' })
          )}
        </ul>
      </React.Fragment>;

      veteranDetails = <React.Fragment>
        <h2>Veteran Details</h2>
        <ul>
          {this.renderListElements(
            this.getDetails({
              nameField: 'veteran_full_name',
              genderField: 'veteran_gender',
              dobField: 'veteran_date_of_birth'
            })
          )}
        </ul>
      </React.Fragment>;
    }

    return <div {...appellantDetailStyling}>
      {appellantDetails}
      {veteranDetails}
    </div>;
  };
}

AppellantDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
