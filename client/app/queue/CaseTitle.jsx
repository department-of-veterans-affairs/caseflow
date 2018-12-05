import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { COLORS } from '../constants/AppConstants';
import CopyTextButton from '../components/CopyTextButton';
import { toggleVeteranCaseList } from './uiReducer/uiActions';
import HearingBadge from './components/HearingBadge';
import AodBadge from './components/AodBadge';

const containingDivStyling = css({

  display: 'block',
  // Offsets the padding from .cf-app-segment--alt to make the bottom border full width.
  margin: '-2rem -4rem 0 -4rem',
  padding: '0 0 1.5rem 4rem',

  '& > *': {
    display: 'inline-block',
    margin: '0'
  }
});

const headerStyling = css({
  paddingRight: '2.5rem'
});

const listStyling = css({
  listStyleType: 'none',
  verticalAlign: 'super',
  padding: '1rem 0 0 0'
});

const listItemStyling = css({
  display: 'inline',
  padding: '0.5rem 1.5rem 0.5rem 0',
  ':nth-child(1)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' }
});

const viewCasesStyling = css({
  cursor: 'pointer'
});

const badgeStyle = css({
  marginRight: '26px',
  marginLeft: '-20px',
  fontSize: '14px'
});

 const displayNone = css({
  display: 'none'
});

const displayInline = css({
  display: 'inline'
});

class CaseTitle extends React.PureComponent {
  render = () => {
    const {
      appeal,
      veteranCaseListIsVisible
    } = this.props;

    return <CaseTitleScaffolding heading={appeal.veteranFullName}>
      <React.Fragment>
        Veteran ID:&nbsp;
        <CopyTextButton text={appeal.veteranFileNumber} />
      </React.Fragment>

      <span {...viewCasesStyling}>
        <Link onClick={this.props.toggleVeteranCaseList}>
          { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
        </Link>
      </span>

      <span>
        <span className={appeal.hearings.length > 0 ? null : displayNone} {...badgeStyle}>
          <HearingBadge hearing={appeal.hearings[0]} {...displayInline} />
        </span>

        <span className={appeal.isAdvancedOnDocket ? null : displayNone} {...badgeStyle}>
          <AodBadge appeal={appeal} className={displayInline} />
        </span>
      </span>

    </CaseTitleScaffolding>;
  }
}

CaseTitle.propTypes = {
  appeal: PropTypes.object.isRequired,
  redirectUrl: PropTypes.string.isRequired,
  appealId: PropTypes.string.isRequired,
  taskType: PropTypes.string,
  analyticsSource: PropTypes.string
};

CaseTitle.defaultProps = {
  taskType: 'Draft Decision',
  analyticsSource: 'queue_task'
};

const mapStateToProps = (state) => ({
  veteranCaseListIsVisible: state.ui.veteranCaseListIsVisible,
  userIsVsoEmployee: state.ui.userIsVsoEmployee
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleVeteranCaseList
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseTitle);

const CaseTitleScaffolding = (props) => <div {...containingDivStyling}>
  <h1 {...headerStyling}>{props.heading}</h1>
  <ul {...listStyling}>
    {props.children.map((child, i) => child && <li key={i} {...listItemStyling}>{child}</li>)}
  </ul>
</div>;
