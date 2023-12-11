import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import COPY from 'app/../COPY';
import Dropdown from '../../../components/Dropdown';

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
  padding: '0 0 4rem 0',
  display: 'flex',
  flexWrap: 'wrap'
});

const columnStyling = css({
  flexBasis: '0',
  webkitBoxFlex: '1',
  msFlexPositive: '1',
  flexGrow: '1',
  maxWidth: '100%'
});

const dropDownDiv = css({
  marginTop: '-10px',
  flexBasis: '0',
  webkitBoxFlex: '1',
  msFlexPositive: '1',
  flexGrow: '1',
  maxWidth: '100%'
});

class ReviewPackageCaseTitle extends React.PureComponent {
  render = () => {
    return (
      <div>
        <CaseTitleScaffolding heading={COPY.CORRESPONDENCE_REVIEW_PACKAGE_TITLE} />
        <CaseSubTitleScaffolding />
      </div>
    );
  };
}

const CaseTitleScaffolding = (props) => (
  <div {...containingDivStyling}>
    <h1 {...headerStyling}>{props.heading}</h1>
  </div>
);

const CaseSubTitleScaffolding = () => (
  <div {...listStyling}>
    <div {...columnStyling}>
      {COPY.CORRESPONDENCE_REVIEW_PACKAGE_SUB_TITLE}
    </div>
    <div {...dropDownDiv} style = {{ maxWidth: '25%' }}>
      <Dropdown
        options={[
          { value: 'Split package', displayText: 'Split package' },
          { value: 'Merge package', displayText: 'Merge package' },
          { value: 'Remove package from Caseflow', displayText: 'Remove package from Caseflow' },
          { value: 'Reassign package', displayText: 'Reassign package' }
        ]}
        defaultText="Request package action"
        name="package-action-dropdown"
      />
    </div>
  </div>
);

CaseTitleScaffolding.propTypes = {
  heading: PropTypes.string
};

export default ReviewPackageCaseTitle;
