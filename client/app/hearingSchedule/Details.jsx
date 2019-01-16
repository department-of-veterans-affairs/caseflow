import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { Link } from 'react-router-dom';
import { css } from 'glamor';

import CopyTextButton from '../components/CopyTextButton';
import DetailsOverview from './components/DetailsOverview';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import * as DateUtil from '../util/DateUtil';
import {
  JudgeDropdown,
  HearingCoordinatorDropdown,
  HearingRoomDropdown,
  RegionalOfficeDropdown,
  HearingDateDropdown
} from './components/DataDropdowns/index';

const inlineRow = css({
  '& > *': {
    display: 'inline-block',
    paddingRight: '25px',
    verticalAlign: 'middle'
  }
});

class HearingDetails extends React.Component {

  constructor(props) {
    super(props);

    this.state = {
      vlj: null,
      hearingCoordinator: null,
      room: null,
      date: null,
      ro: null,
      notes: null,
      waive: null
    };
  }

  overviewColumns = () => {

    const {
      scheduledFor,
      docketNumber,
      regionalOfficeName,
      //  hearing_location,
      disposition,
      readableRequestType,
      aod
    } = this.props.hearing;

    return [
      {
        label: 'Hearing Date',
        value: DateUtil.formatDate(scheduledFor)
      },
      {
        label: 'Docket Number',
        value: docketNumber
      },
      {
        label: 'Regional office',
        value: regionalOfficeName
      },
      {
        label: 'Hearing Location',
        value: ' '
      },
      {
        label: 'Disposition',
        value: disposition
      },
      {
        label: 'Type',
        value: readableRequestType
      },
      {
        label: 'AOD Status',
        value: aod
      }
    ];
  }

  render() {
    const {
      veteranFirstName,
      veteranLastName,
      vbmsId
    } = this.props.hearing;

    return (
      <AppSegment filledBackground>
        <div {...inlineRow}>
          <h1 className="cf-margin-bottom-0">{`${veteranFirstName} ${veteranLastName}`}</h1>
          <div>Veteran ID: <CopyTextButton text={vbmsId} /></div>
        </div>

        <div className="cf-help-divider"></div>

        <h2>Hearing Details</h2>
        <DetailsOverview columns={this.overviewColumns()} />

        <div className="cf-help-divider"></div>

        <div>
          <JudgeDropdown
            value={this.state.vlj}
            onChange={(vlj) => this.setState({ vlj })}
          />
        <HearingRoomDropdown
            value={this.state.room}
            onChange={(room) => this.setState({ room })}
          />
        <HearingCoordinatorDropdown
            value={this.state.coordinator}
            onChange={(coordinator) => this.setState({ coordinator })}
          />
        <RegionalOfficeDropdown
            value={this.state.ro}
            onChange={(ro) => this.setState({ ro })}
          />
        <HearingDateDropdown
              regionalOffice={'RO01'}
              value={this.state.date}
              onChange={(date) => this.setState({ date })}
            />
          <div {...inlineRow}>
          </div>

        </div>
      </AppSegment>
    );
  }
}

HearingDetails.propTypes = {
  hearing: PropTypes.object.isRequired
};

export default connect(
  null
)(HearingDetails);
