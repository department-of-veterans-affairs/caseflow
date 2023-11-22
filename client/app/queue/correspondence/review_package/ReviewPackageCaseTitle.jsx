import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import COPY from 'app/../COPY';
import SearchableDropdown from '../../../components/SearchableDropdown';

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

const tagStyling = css({
  '& .cf-select__control': {
    maxWidth: '63rem !important',
  },
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

const defaultSelectedValue = () => {
  return { label: 'Split package', value: 'Split package' };
};

const CaseSubTitleScaffolding = () => (
  <div {...listStyling}>
    <div {...columnStyling}>
      {COPY.CORRESPONDENCE_REVIEW_PACKAGE_SUB_TITLE}
    </div>
    <div {...dropDownDiv} style = {{ maxWidth: '25%' }}>
      <SearchableDropdown
        styling={tagStyling}
        value={defaultSelectedValue}
        options={[
          { value: 'Split package', label: 'Split package', id: 1 },
          { value: 'Merge package', label: 'Merge package', id: 2 },
          { value: 'Remove package from Caseflow', label: 'Remove package from Caseflow', id: 3 },
          { value: 'Reassign package', label: 'Reassign package', id: 4 }
        ]}
        placeholder="Request package action"
      />
    </div>
  </div>
);

CaseTitleScaffolding.propTypes = {
  heading: PropTypes.string
};

export default ReviewPackageCaseTitle;
