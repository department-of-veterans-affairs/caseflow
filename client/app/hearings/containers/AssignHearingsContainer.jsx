import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

import { AssignHearings } from '../components/assignHearings/AssignHearings';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { RegionalOfficeDropdown } from '../../components/DataDropdowns';
import { encodeQueryParams, getQueryParams } from '../../util/QueryParamsUtil';
import { getMinutesToMilliseconds } from '../../util/DateUtil';
import {
  onReceiveUpcomingHearingDays,
  onSelectedHearingDayChange
} from '../actions/hearingScheduleActions';
import { onRegionalOfficeChange } from '../../components/common/actions';
import { setUserCssId } from '../../queue/uiReducer/uiActions';
import ApiUtil from '../../util/ApiUtil';
import COPY from '../../../COPY';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { ENDPOINT_NAMES } from '../constants';

const centralOfficeStaticEntry = [{
  label: 'Central',
  value: 'C'
}];

const roSelectionStyling = css({
  marginTop: '10px',
  marginBottom: '10px'
});

class AssignHearingsContainer extends React.PureComponent {

  componentDidMount = () => {
    this.props.setUserCssId(this.props.userCssId);
  }

  onRegionalOfficeChange = (value) => {
    if (value) {
      const currentQueryParams = getQueryParams(window.location.search);

      // Replace regional_office_key parameter with the new value. Do not overwrite
      // any parameters that are currently set in the query string.
      currentQueryParams.regional_office_key = value?.key;

      window.history.replaceState('', '', encodeQueryParams(currentQueryParams));
    }

    this.props.onRegionalOfficeChange(value);
  }

  loadUpcomingHearingDays = () => {
    const { selectedRegionalOffice } = this.props;

    if (!selectedRegionalOffice) {
      return;
    }

    const requestUrl = `/hearings/schedule/assign/hearing_days?regional_office=${selectedRegionalOffice}`;

    return ApiUtil.get(requestUrl, { timeout: { response: getMinutesToMilliseconds(5) } },
      ENDPOINT_NAMES.UPCOMING_HEARING_DAYS
    ).then((response) => {
      const resp = ApiUtil.convertToCamelCase(response.body);

      this.props.onReceiveUpcomingHearingDays(_.keyBy(resp.hearingDays, 'id'));
      this.props.onSelectedHearingDayChange(resp.hearingDays[0]);
    });
  };

  render = () => {
    const { selectedRegionalOffice } = this.props;

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
            value={selectedRegionalOffice || getQueryParams(window.location.search).regional_office_key}
            staticOptions={centralOfficeStaticEntry}
          />
        </section>
        {selectedRegionalOffice &&
          <LoadingDataDisplay
            key={selectedRegionalOffice || 0}
            createLoadPromise={this.loadUpcomingHearingDays}
            loadingComponentProps={{
              spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
              message: 'Loading appeals to be scheduled for hearings...'
            }}
          >
            <AssignHearings
              selectedRegionalOffice={selectedRegionalOffice}
              upcomingHearingDays={this.props.upcomingHearingDays}
              onSelectedHearingDayChange={this.props.onSelectedHearingDayChange}
              selectedHearingDay={this.props.selectedHearingDay}
              userId={this.props.userId}
            />
          </LoadingDataDisplay>
        }
      </AppSegment>
    );
  }
}

AssignHearingsContainer.propTypes = {
  onReceiveUpcomingHearingDays: PropTypes.func,
  onRegionalOfficeChange: PropTypes.func,
  onSelectedHearingDayChange: PropTypes.func,
  selectedHearingDay: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),

  // Selected Regional Office Key
  selectedRegionalOffice: PropTypes.string,

  setUserCssId: PropTypes.func,
  upcomingHearingDays: PropTypes.object,
  userCssId: PropTypes.string,
  userId: PropTypes.number
};

const mapStateToProps = (state) => ({
  selectedRegionalOffice: state.components.selectedRegionalOffice?.key,
  upcomingHearingDays: state.hearingSchedule.upcomingHearingDays,
  selectedHearingDay: state.hearingSchedule.selectedHearingDay
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRegionalOfficeChange,
  onSelectedHearingDayChange,
  onReceiveUpcomingHearingDays,
  setUserCssId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingsContainer);
