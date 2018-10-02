import React from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import { css } from 'glamor';
import _ from 'lodash';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Table from '../../components/Table';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class DailyDocket extends React.Component {

  getAppellantInformation = (hearing) => {
    return <div><b>{hearing.appellantName} ({hearing.vbmsId})</b> <br />
      {hearing.appellantAddress} <br />
      {hearing.appellantCity}, {hearing.appellantState} {hearing.appellantZipCode}
      <p>{hearing.issueCount} issues</p>
    </div>;
  };

  getDispositionDropdown = (hearing) => {
    return <SearchableDropdown
      name="Disposition"
      placeholder="Select disposition"
      options={[
        {
          label: "Held",
          value: "held"
        }
      ]}
      value={hearing.disposition}
      onChange={() => {}}
    />
  };

  render() {
    const dailyDocketColumns = [
      {
        header: '',
        align: 'left',
        valueName: 'number'
      },
      {
        header: 'Appellant/Veteran ID',
        align: 'left',
        valueName: 'appellantInformation'
      },
      {
        header: 'Time/RO(s)',
        align: 'left',
        valueName: 'hearingTime'
      },
      {
        header: 'Representative',
        align: 'left',
        valueName: 'representative'
      },
      {
        header: 'Actions',
        align: 'left',
        valueName: 'hearingLocation'
      },
      {
        header: '',
        align: 'left',
        valueName: 'hearingDay'
      },
      {
        header: '',
        align: 'left',
        valueName: 'disposition'
      },
    ];

    const dailyDocketRows = _.map(this.props.hearings, (hearing) => ({
      number: '1.',
      appellantInformation: this.getAppellantInformation(hearing),
      hearingTime: <div>{hearing.hearingTime} <br /> {hearing.hearingLocation}</div>,
      representative: <div>{hearing.representative} <br /> {hearing.representativeName}</div>,
      hearingLocation: 'Houston, TX',
      hearingDay: '2018-03-10',
      disposition: this.getDispositionDropdown(hearing)
    }));

    return <AppSegment filledBackground>
      <div className="cf-push-left">
        <h1>Daily Docket ({moment(this.props.hearingDate).format('ddd M/DD/YYYY')})</h1> <br />
      <Link to="/schedule">&lt; Back to schedule</Link>
      </div>
      <span className="cf-push-right">
        VLJ: {this.props.vlj} <br />
        Coordinator: {this.props.coordinator} <br />
        Hearing type: {this.props.hearingType}
      </span>
      <Table
        columns={dailyDocketColumns}
        rowObjects={dailyDocketRows}
        summary="dailyDocket"
      />
    </AppSegment>;
  }
}

DailyDocket.propTypes = {
  vlj: PropTypes.string,
  coordinator: PropTypes.string,
  hearingType: PropTypes.string,
  hearingDate: PropTypes.string,
  hearings: PropTypes.object
};
