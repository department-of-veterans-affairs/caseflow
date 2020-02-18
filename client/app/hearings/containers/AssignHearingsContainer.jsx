import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { css } from 'glamor';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';
import _ from 'lodash';

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
import AssignHearings from '../components/assignHearings/AssignHearings';
import COPY from '../../../COPY.json';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';

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

  onRegionalOfficeChange = (value, label) => {
    if (value) {
      const currentQueryParams = getQueryParams(window.location.search);

      // Replace regional_office_key parameter with the new value. Do not overwrite
      // any parameters that are currently set in the query string.
      currentQueryParams.regional_office_key = value;

      window.history.replaceState('', '', encodeQueryParams(currentQueryParams));
    }

    this.props.onRegionalOfficeChange({ label,
      value });
  }

  loadUpcomingHearingDays = () => {
    const { selectedRegionalOffice } = this.props;
    const roValue = selectedRegionalOffice ? selectedRegionalOffice.value : null;

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

  render = () => {
    const { selectedRegionalOffice } = this.props;
    const roValue = selectedRegionalOffice ? selectedRegionalOffice.value : null;

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
            value={roValue || getQueryParams(window.location.search).regional_office_key}
            staticOptions={centralOfficeStaticEntry}
          />
        </section>
        {roValue &&
          <LoadingDataDisplay
            key={roValue || 0}
            createLoadPromise={this.loadUpcomingHearingDays}
            loadingComponentProps={{
              spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
              message: 'Loading appeals to be scheduled for hearings...'
            }}
          >
            <AssignHearings
              selectedRegionalOffice={this.props.selectedRegionalOffice.value}
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
  selectedRegionalOffice: PropTypes.shape({
    label: PropTypes.string,
    value: PropTypes.string
  }),
  setUserCssId: PropTypes.func,
  upcomingHearingDays: PropTypes.object,
  userCssId: PropTypes.string,
  userId: PropTypes.number
};

const mapStateToProps = (state) => ({
  selectedRegionalOffice: state.components.selectedRegionalOffice,
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
