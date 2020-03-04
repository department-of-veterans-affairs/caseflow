import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import COPY from '../../../COPY';
import _ from 'lodash';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import ApiUtil from '../../util/ApiUtil';
import { getMinutesToMilliseconds } from '../../util/DateUtil';
import {
  onReceiveUpcomingHearingDays,
  onSelectedHearingDayChange,
  onReceiveAppealsReadyForHearing
} from '../actions/hearingScheduleActions';
import { onRegionalOfficeChange } from '../../components/common/actions';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { COLORS, LOGO_COLORS } from '../../constants/AppConstants';
import { onReceiveTasks } from '../../queue/QueueActions';
import { setUserCssId } from '../../queue/uiReducer/uiActions';
import { RegionalOfficeDropdown } from '../../components/DataDropdowns';
import AssignHearings from '../components/assignHearings/AssignHearings';
import { getQueryParams } from '../../util/QueryParamsUtil';

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
  }

  onRegionalOfficeChange = (value, label) => {

    if (value) {
      window.history.replaceState('', '', `?roValue=${value}`);
    }

    this.props.onRegionalOfficeChange({
      label,
      value
    });
  }

  loadUpcomingHearingDays = (roValue) => {
    if (!roValue) {
      return;
    }

    const requestUrl = `/hearings/schedule/assign/hearing_days?regional_office=${roValue}`;

    return ApiUtil.get(requestUrl, { timeout: { response: getMinutesToMilliseconds(5) } }
    ).then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);

      this.props.onReceiveUpcomingHearingDays(_.keyBy(resp.hearingDays, 'id'));
      this.props.onSelectedHearingDayChange(resp.hearingDays[0]);
    });
  };

  loadAppealsReadyForHearing = (roValue) => {
    if (!roValue) {
      return;
    }

    const requestUrl = `/cases_to_schedule/${roValue}`;

    return ApiUtil.get(requestUrl, { timeout: { response: getMinutesToMilliseconds(5) } }
    ).then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);

      this.props.onReceiveAppealsReadyForHearing(resp.data);
    });
  };

  getNoUpcomingError = () => {
    if (this.props.selectedRegionalOffice) {
      return <div className="usa-input-error-message usa-input-error" {...smallTopMargin}>
        <span>{this.props.selectedRegionalOffice.value && this.props.selectedRegionalOffice.label} has
          no upcoming hearing days.</span><br />
        <p>Please verify that this RO's hearing days are in the current schedule.</p>
      </div>;
    }
  }

  createLoadPromise = () => {
    const { selectedRegionalOffice } = this.props;
    const roValue = selectedRegionalOffice ? selectedRegionalOffice.value : null;

    return Promise.all([
      this.loadUpcomingHearingDays(roValue),
      this.loadAppealsReadyForHearing(roValue)
    ]);
  }

  render = () => {
    const { selectedRegionalOffice } = this.props;
    const roValue = selectedRegionalOffice ? selectedRegionalOffice.value : null;

    // Remove `displayPowerOfAttorneyColumn` when pagination lands (#11757)
    return (
      <AppSegment filledBackground>
        <h1>{COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_HEADER}</h1>
        <Link
          name="view-schedule"
          to="/schedule">
          {COPY.HEARING_SCHEDULE_ASSIGN_HEARINGS_VIEW_SCHEDULE_LINK}
        </Link>
        <section className="usa-form-large" {...roSelectionStyling}>
          <RegionalOfficeDropdown
            onChange={this.onRegionalOfficeChange}
            validateValueOnMount
            value={roValue || getQueryParams(window.location.search).roValue}
            staticOptions={centralOfficeStaticEntry}
          />
        </section>
        {roValue && <LoadingDataDisplay
          key={roValue || 0}
          createLoadPromise={this.createLoadPromise}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
            message: 'Loading appeals to be scheduled for hearings...'
          }}>

          <AssignHearings
            selectedRegionalOffice={this.props.selectedRegionalOffice.value}
            upcomingHearingDays={this.props.upcomingHearingDays}
            onSelectedHearingDayChange={this.props.onSelectedHearingDayChange}
            selectedHearingDay={this.props.selectedHearingDay}
            appealsReadyForHearing={this.props.appealsReadyForHearing}
            userId={this.props.userId}
            onReceiveTasks={this.props.onReceiveTasks}
            displayPowerOfAttorneyColumn={this.props.displayPowerOfAttorneyColumn} />
        </LoadingDataDisplay>}
      </AppSegment>
    );
  }
}

AssignHearingsContainer.propTypes = {
  appealsReadyForHearing: PropTypes.object,
  onReceiveAppealsReadyForHearing: PropTypes.func,
  onReceiveTasks: PropTypes.func,
  onReceiveUpcomingHearingDays: PropTypes.func,
  onRegionalOfficeChange: PropTypes.func,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  selectedRegionalOffice: PropTypes.shape({
    label: PropTypes.string,
    value: PropTypes.string
  }),
  setUserCssId: PropTypes.func,
  upcomingHearingDays: PropTypes.object,
  userCssId: PropTypes.string,
  userId: PropTypes.number,
  // Remove when pagination lands (#11757)
  displayPowerOfAttorneyColumn: PropTypes.bool
};

const mapStateToProps = (state) => ({
  selectedRegionalOffice: state.components.selectedRegionalOffice,
  upcomingHearingDays: state.hearingSchedule.upcomingHearingDays,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay,
  appealsReadyForHearing: state.hearingSchedule.appealsReadyForHearing
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRegionalOfficeChange,
  onSelectedHearingDayChange,
  onReceiveUpcomingHearingDays,
  onReceiveAppealsReadyForHearing,
  onReceiveTasks,
  setUserCssId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingsContainer);
