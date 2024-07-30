import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { COLORS } from 'app/constants/AppConstants';
import BadgeArea from 'app/components/badges/BadgeArea';
import CopyTextButton from 'app/components/CopyTextButton';
import { toggleVeteranCaseList } from './uiReducer/uiActions';

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
  ':not(:last-child)': { borderRight: `1px solid ${COLORS.GREY_LIGHT}` },
  ':not(:first-child)': { paddingLeft: '1.5rem' }
});

const viewCasesStyling = css({
  cursor: 'pointer'
});

class CaseTitle extends React.PureComponent {
  render = () => {
    const { appeal, veteranCaseListIsVisible } = this.props;

    return (
      <CaseTitleScaffolding heading={this.props.titleHeader === '' ? appeal.veteranFullName : this.props.titleHeader}>
        <React.Fragment>
          Veteran ID:&nbsp;
          <CopyTextButton text={appeal.veteranFileNumber} label="Veteran ID" />
        </React.Fragment>

        { !this.props.hideCaseView &&
        <>
          <span {...viewCasesStyling}>
            <Link href="#" onClick={this.props.toggleVeteranCaseList}>
              {veteranCaseListIsVisible ? 'Hide ' : 'View '} all cases
            </Link>
          </span>
          <BadgeArea appeal={appeal} isHorizontal />
        </>
        }
      </CaseTitleScaffolding>
    );
  };
}

CaseTitle.propTypes = {
  appeal: PropTypes.object.isRequired,
  taskType: PropTypes.string,
  analyticsSource: PropTypes.string,
  veteranCaseListIsVisible: PropTypes.bool,
  toggleVeteranCaseList: PropTypes.func,
  titleHeader: PropTypes.string,
  hideCaseView: PropTypes.bool
};

CaseTitle.defaultProps = {
  taskType: 'Draft Decision',
  analyticsSource: 'queue_task',
  titleHeader: ''
};

const CaseTitleScaffolding = (props) => (
  <div {...containingDivStyling}>
    <h1 {...headerStyling}>{props.heading}</h1>
    <div {...listStyling}>
      {props.children.map(
        (child, i) =>
          child && (
            <div key={i} {...listItemStyling}>
              {child}
            </div>
          )
      )}
    </div>
  </div>
);

CaseTitleScaffolding.propTypes = {
  heading: PropTypes.string,
  children: PropTypes.node,
};

const mapStateToProps = (state) => ({
  veteranCaseListIsVisible: state.ui.veteranCaseListIsVisible,
  userIsVsoEmployee: state.ui.userIsVsoEmployee
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      toggleVeteranCaseList
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseTitle);
