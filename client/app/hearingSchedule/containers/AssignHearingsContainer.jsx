import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import COPY from '../../../COPY.json';
import _ from 'lodash';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ApiUtil from '../../util/ApiUtil';
import {
  onReceiveUpcomingHearingDays,
  onSelectedHearingDayChange,
  onReceiveVeteransReadyForHearing
} from '../actions';
import { onRegionalOfficeChange } from '../../components/common/actions';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { COLORS, LOGO_COLORS } from '../../constants/AppConstants';
import { onReceiveTasks } from '../../queue/QueueActions';
import { setUserCssId } from '../../queue/uiReducer/uiActions';
import RoSelectorDropdown from '../../components/RoSelectorDropdown';
import AssignHearings from '../components/AssignHearings';

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

const smallTopMargin = css({
  fontStyle: 'italic',
  '.usa-input-error': {
    marginTop: '1rem'
  },
  '.usa-input-error-message': {
    paddingBottom: '0',
    paddingTop: '0',
    right: '0'
  },
  '& > p': {
    fontWeight: '500',
    color: COLORS.RED_DARK,
    marginBottom: '0',
    fontSize: '1.7rem',
    marginTop: '1px'
  }
});

const roSelectionStyling = css({
  marginTop: '10px',
  marginBottom: '10px' });

class AssignHearingsContainer extends React.PureComponent {

  componentDidMount = () => {
    this.props.setUserCssId(this.props.userCssId);
    this.props.onRegionalOfficeChange('');
  }

  loadUpcomingHearingDays = () => {
    if (!this.props.selectedRegionalOffice) {
      return;
    }

    const regionalOfficeKey = this.props.selectedRegionalOffice.value;
    const requestUrl = `/hearings/schedule/assign/hearing_days?regional_office=${regionalOfficeKey}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveUpcomingHearingDays(_.keyBy(resp.hearingDays, 'id'));
      this.props.onSelectedHearingDayChange(resp.hearingDays[0]);
    });
  };

  loadVeteransReadyForHearing = () => {
    if (!this.props.selectedRegionalOffice) {
      return;
    }

    const regionalOfficeKey = this.props.selectedRegionalOffice.value;
    const requestUrl = `/hearings/schedule/assign/veterans?regional_office=${regionalOfficeKey}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveVeteransReadyForHearing(_.keyBy(resp.veterans, 'vbmsId'));
    });
  };

  getNoUpcomingError = () => {
    if (this.props.selectedRegionalOffice) {
      return <div className="usa-input-error-message usa-input-error" {...smallTopMargin}>
        <span>{this.props.selectedRegionalOffice && this.props.selectedRegionalOffice.label} has
          no upcoming hearing days.</span><br />
        <p>Please verify that this RO's hearing days are in the current schedule.</p>
      </div>;
    }
  }

  createLoadPromise = () => {
    return Promise.all([
      this.loadUpcomingHearingDays(), this.loadVeteransReadyForHearing()
    ]);
  }

  render = () => {
    return (
      <AppSegment filledBackground>
        <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
        <Link
          name="view-schedule"
          to="/schedule">
          {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
        </Link>
        <section className="usa-form-large" {...roSelectionStyling}>
          <RoSelectorDropdown
            onChange={this.props.onRegionalOfficeChange}
            value={this.props.selectedRegionalOffice ? this.props.selectedRegionalOffice : null}
            staticOptions={centralOfficeStaticEntry}
          />
        </section>
        {this.props.selectedRegionalOffice && <LoadingDataDisplay
          key={this.props.selectedRegionalOffice.value}
          createLoadPromise={this.createLoadPromise}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
            message: 'Loading appeals to be scheduled for hearings...'
          }}>

          {_.isEmpty(this.props.upcomingHearingDays) && this.getNoUpcomingError()}

          <AssignHearings
            selectedRegionalOffice={this.props.selectedRegionalOffice}
            upcomingHearingDays={this.props.upcomingHearingDays}
            onSelectedHearingDayChange={this.props.onSelectedHearingDayChange}
            selectedHearingDay={this.props.selectedHearingDay}
            veteransReadyForHearing={this.props.veteransReadyForHearing}
            userId={this.props.userId}
            onReceiveTasks={this.props.onReceiveTasks} />
        </LoadingDataDisplay>}
      </AppSegment>
    );
  }
}

AssignHearings.propTypes = {
  userId: PropTypes.number,
  userCssId: PropTypes.string
};

const mapStateToProps = (state) => ({
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  upcomingHearingDays: state.hearingSchedule.upcomingHearingDays,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay,
  veteransReadyForHearing: state.hearingSchedule.veteransReadyForHearing
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRegionalOfficeChange,
  onSelectedHearingDayChange,
  onReceiveUpcomingHearingDays,
  onReceiveVeteransReadyForHearing,
  onReceiveTasks,
  setUserCssId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingsContainer);
