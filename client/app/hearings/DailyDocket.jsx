import React from 'react';
import PropTypes from 'prop-types';
import DocketHearingRow from './components/DocketHearingRow';
import moment from 'moment';
import { Link } from 'react-router-dom';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

export class DailyDocket extends React.Component {

  saveDailyDocketInLocalStorage = (docket) => {
    localStorage.setItem('dailyDocket', JSON.stringify(docket));
    localStorage.setItem('dailyDocketDate', this.props.date);
  };

  render() {
    const docket = this.props.docket;

    return <div>
      <AppSegment extraClassNames="cf-hearings" noMarginTop filledBackground>
        <div className="cf-title-meta-right">
          <div className="title cf-hearings-title-and-judge">
            <h1>Daily Docket</h1>
            <span>VLJ: {this.props.veteran_law_judge.full_name}</span>
          </div>
          <div className="meta">
            <div>{moment(docket[0].date).format('ddd l')}</div>
            <div>Hearing Type: {docket[0].request_type}</div>
          </div>
        </div>
        <table className="cf-hearings-docket">
          <thead>
            <tr>
              <th></th>
              <th>Prep</th>
              <th>Time/RO(s)</th>
              <th>Veteran/Veteran ID</th>
              <th>Representative</th>
              <th>
                Actions
              </th>
            </tr>
          </thead>
          {docket.map((hearing, index) =>
            <DocketHearingRow
              key={hearing.id}
              index={index}
              hearing={hearing}
              hearingDate={this.props.date}
            />
          )}
        </table>
      </AppSegment>
      <div className="cf-alt--actions">
        <div className="cf-push-left">
          <Link to="/hearings/dockets" onClick={this.saveDailyDocketInLocalStorage(this.props.docket)}>&lt; Back to Your Hearing Days</Link>
        </div>
      </div>
    </div>;
  }
}

export default DailyDocket;

DailyDocket.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired
};
