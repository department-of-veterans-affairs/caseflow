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

const dropDownDiv = css({
  marginTop: '-10px',
  flexBasis: '0',
  webkitBoxFlex: '1',
  msFlexPositive: '1',
  flexGrow: '1',
  maxWidth: '100%'
});

const ReviewPackageCaseTitle = (props) => {
  return (
    <div>
      <CaseTitleScaffolding />
      <CaseSubTitleScaffolding handlePackageActionModal={props.handlePackageActionModal} />
    </div>
  );
};

const CaseTitleScaffolding = () => (
  <div {...containingDivStyling}>
    <h1 {...headerStyling}>{COPY.CORRESPONDENCE_REVIEW_PACKAGE_TITLE}</h1>
  </div>
);

const CaseSubTitleScaffolding = (props) => (
  <div {...listStyling}>
    <div {...columnStyling}>
      {COPY.CORRESPONDENCE_REVIEW_PACKAGE_SUB_TITLE}
    </div>
    <div {...dropDownDiv} style = {{ maxWidth: '25%' }}>
      <SearchableDropdown
        options={[
          { value: 'splitPackage', label: 'Split package' },
          { value: 'mergePackage', label: 'Merge package' },
          { value: 'removePackage', label: 'Remove package from Caseflow' },
          { value: 'reassignPackage', label: 'Reassign package' }
        ]}
        onChange={(option) => props.handlePackageActionModal(option.value)}
        placeholder="Request package action"
        defaultText="Request package action"
      />
    </div>
  </div>
);

ReviewPackageCaseTitle.propTypes = {
  handlePackageActionModal: PropTypes.func
};

CaseSubTitleScaffolding.propTypes = {
  handlePackageActionModal: PropTypes.func
};

export default ReviewPackageCaseTitle;
