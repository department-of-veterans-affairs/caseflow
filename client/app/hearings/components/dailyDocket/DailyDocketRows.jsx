import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { sortHearings } from '../../utils';
import DailyDocketRow from './DailyDocketRow';
import { docketRowStyle } from './style';

const rowsMargin = css({
  marginLeft: '-40px',
  marginRight: '-40px',
  marginBottom: '-40px'
});

const Header = ({ user }) => (
  <div
    {...docketRowStyle}
    {...css({
      '& *': {
        background: 'none !important'
      },
      '& > div > div': { verticalAlign: 'bottom' }
    })}
    className={user.userHasHearingPrepRole ? 'judge-view' : ''}
  >
    <div>
      <div>{user.userHasHearingPrepRole && <strong>Prep</strong>}</div>
      <div />
      <div>
        <strong>Appellant/Veteran ID/Representative</strong>
      </div>
      <div>
        <strong>Type/Time/RO</strong>
      </div>
    </div>
    <div>
      <div>
        <strong>Actions</strong>
      </div>
    </div>
  </div>
);

Header.propTypes = {
  user: PropTypes.shape({
    userHasHearingPrepRole: PropTypes.bool
  })
};

export default class DailyDocketHearingRows extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      hearings: []
    };
  }

  componentDidMount() {
    const sortedHearings = sortHearings(this.props.hearings);

    this.setState({ hearings: sortedHearings });
  }

  render() {
    const {
      readOnly,
      regionalOffice,
      openDispositionModal,
      user,
      saveHearing,
      hidePreviouslyScheduled,
      hearingDayDate
    } = this.props;

    return (
      <div {...rowsMargin}>
        <Header user={user} />
        <div>
          {this.state.hearings.length > 0 &&
            this.state.hearings.map((hearing, index) => (
              <DailyDocketRow
                hearing={hearing}
                hearingId={hearing.externalId}
                index={index}
                readOnly={readOnly}
                hidePreviouslyScheduled={hidePreviouslyScheduled}
                user={user}
                saveHearing={saveHearing}
                regionalOffice={regionalOffice}
                openDispositionModal={openDispositionModal}
                hearingDayDate={hearingDayDate}
              />
            ))}
        </div>
      </div>
    );
  }
}

DailyDocketHearingRows.propTypes = {
  hearings: PropTypes.object,
  openDispositionModal: PropTypes.func,
  readOnly: PropTypes.bool,
  regionalOffice: PropTypes.string,
  saveHearing: PropTypes.func,
  hidePreviouslyScheduled: PropTypes.bool,
  user: PropTypes.shape({
    userHasHearingPrepRole: PropTypes.bool
  }),
  hearingDayDate: PropTypes.string
};
