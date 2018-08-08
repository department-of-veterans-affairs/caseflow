import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { CATEGORIES } from './constants';
import { COLORS } from '../constants/AppConstants';
import ReaderLink from './ReaderLink';

import { toggleVeteranCaseList } from './uiReducer/uiActions';

const containingDivStyling = css({
  borderBottom: `1px solid ${COLORS.GREY_LIGHT}`,
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
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' }
});

const viewCasesStyling = css({
  cursor: 'pointer'
});

class CaseTitle extends React.PureComponent {
  render = () => {
    const {
      appeal,
      appealId,
      redirectUrl,
      taskType,
      analyticsSource,
      veteranCaseListIsVisible
    } = this.props;

    return <CaseTitleScaffolding heading={appeal.attributes.veteran_full_name}>
      <React.Fragment>Veteran ID: <b>{appeal.attributes.vbms_id}</b></React.Fragment>
      <ReaderLink
        appealId={appealId}
        analyticsSource={CATEGORIES[analyticsSource.toUpperCase()]}
        redirectUrl={redirectUrl}
        appeal={appeal}
        taskType={taskType}
        longMessage />
      <span {...viewCasesStyling}>
        <Link onClick={this.props.toggleVeteranCaseList}>
          { veteranCaseListIsVisible ? 'Hide' : 'View' } all cases
        </Link>
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
  veteranCaseListIsVisible: state.ui.veteranCaseListIsVisible
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  toggleVeteranCaseList
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseTitle);

const CaseTitleScaffolding = (props) => <div {...containingDivStyling}>
  <h1 {...headerStyling}>{props.heading}</h1>
  <ul {...listStyling}>
    {props.children.map((child, i) => <li key={i} {...listItemStyling}>{child}</li>)}
  </ul>
</div>;
