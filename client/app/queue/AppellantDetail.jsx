import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import _ from 'lodash';

import BareList from '../components/BareList';
import { boldText, CATEGORIES, TASK_ACTIONS, INTERACTION_TYPES } from './constants';
import { DateString } from '../util/DateUtil';

const detailHeaderStyling = css({
  marginBottom: '5px'
});
const detailListStyling = css({
  paddingLeft: 0,
  listStyle: 'none',
  marginBottom: '3rem'
});
const addressIndentStyling = (secondLine) => css({
  marginLeft: secondLine ? '12.5rem' : 0
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
    const streetAddress = addressLine2 ? `${addressLine1} ${addressLine2}` : addressLine1;

    return <React.Fragment>
      {streetAddress && <React.Fragment><span>{streetAddress},</span><br /></React.Fragment>}
      <span {...addressIndentStyling(streetAddress)}>{city}, {state} {zip} {country === 'USA' ? '' : country}</span>
    </React.Fragment>;
  };

  getPreferredPronoun = (genderFieldName) => this.getAppealAttr(genderFieldName) === 'F' ? 'She/Her' : 'He/His';

  veteranIsAppellant = () => _.isNull(this.getAppealAttr('appellant_full_name'));

  getDetails = ({ nameField, genderField, dobField, addressField, relationField }) => {
    const details = [{
      label: 'Name',
      value: this.getAppealAttr(nameField)
    }];

    if (genderField && this.getAppealAttr(genderField)) {
      details.push({
        label: 'Preferred pronoun',
        value: this.getPreferredPronoun(genderField)
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

    const getDetailField = ({ label, value }) => () => <React.Fragment>
      <span {...boldText}>{label}:</span> {value}
    </React.Fragment>;

    return <BareList ListElementComponent="ul" items={details.map(getDetailField)} />;
  };

  componentDidMount() {
    window.analyticsEvent(CATEGORIES.QUEUE_TASK, TASK_ACTIONS.VIEW_APPELLANT_INFO);
  }

  render = () => {
    let appellantDetails;
    let veteranDetails;

    if (this.veteranIsAppellant()) {
      appellantDetails = <React.Fragment>
        <h2 {...detailHeaderStyling}>Veteran Details</h2>
        <span>The veteran is the appellant.</span>
        <ul {...detailListStyling}>
          {this.getDetails({
            nameField: 'veteran_full_name',
            genderField: 'veteran_gender',
            dobField: 'veteran_date_of_birth',
            addressField: 'appellant_address'
          })}
        </ul>
      </React.Fragment>;
    } else {
      appellantDetails = <React.Fragment>
        <h2 {...detailHeaderStyling}>Appellant Details</h2>
        <span>The veteran is not the appellant.</span>
        <ul {...detailListStyling}>
          {this.getDetails({
            nameField: 'appellant_full_name',
            addressField: 'appellant_address',
            relationField: 'appellant_relationship'
          })}
        </ul>
      </React.Fragment>;

      veteranDetails = <React.Fragment>
        <h2 {...detailHeaderStyling}>Veteran Details</h2>
        <ul {...detailListStyling}>
          {this.getDetails({
            nameField: 'veteran_full_name',
            genderField: 'veteran_gender',
            dobField: 'veteran_date_of_birth'
          })}
        </ul>
      </React.Fragment>;
    }

    return <div>
      {appellantDetails}
      {veteranDetails}
    </div>;
  };
}

AppellantDetail.propTypes = {
  appeal: PropTypes.object.isRequired
};
