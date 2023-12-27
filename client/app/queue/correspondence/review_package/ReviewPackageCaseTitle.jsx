import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import Button from '../../../components/Button';
import SearchableDropdown from '../../../components/SearchableDropdown';
import RemovePackageModal from '../component/RemovePackageModal';

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

const removebotton = css({
  float: 'right',
  marginRight: '2rem !important'

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
      <CaseTitleScaffolding correspondence_id = {props.correspondence.id} isReadOnly={props.isReadOnly} />
      <CaseSubTitleScaffolding {...props} isReadOnly={props.isReadOnly} />
    </div>
  );
};

const CaseTitleScaffolding = (props) => {

  const [modalState, setModalState] = useState(false);

  const openModal = () => {
    setModalState(true);
  };
  const closeModal = () => {
    setModalState(false);
  };

  return (
    <div {...containingDivStyling}>
      <h1 {...headerStyling}>{COPY.CORRESPONDENCE_REVIEW_PACKAGE_TITLE}</h1>

      <span {...removebotton}>
        { props.isReadOnly &&
          <Button
            name="Review removal request"
            styling={{ style: { marginRight: '2rem', padding: '15px', fontSize: 'larger' } }}
            classNames={['usa-button-primary']}
            onClick={() => {
              openModal();
            }}
          />
        }
      </span>
      { modalState &&
      <RemovePackageModal
        modalState={modalState}
        setModalState={setModalState}
        onCancel={closeModal}
        correspondence_id = {props.correspondence_id} />
      }
    </div>
  );

};

const CaseSubTitleScaffolding = (props) => (
  <div {...listStyling}>
    <div {...columnStyling}>
      {COPY.CORRESPONDENCE_REVIEW_PACKAGE_SUB_TITLE}
    </div>

    <div {...dropDownDiv} style = {{ maxWidth: '25%' }}>
      { !props.isReadOnly &&
      <SearchableDropdown
        options={[
          { value: 'splitPackage', label: 'Split package' },
          { value: 'mergePackage', label: 'Merge package' },
          { value: 'removePackage', label: 'Remove package from Caseflow' },
          { value: 'reassignPackage', label: 'Reassign package' }
        ]}
        onChange={(option) => props.handlePackageActionModal(option.value)}
        placeholder="Request package action"
        label="Request package action dropdown"
        hideLabel
        name=""
        value={props.packageActionModal}
      /> }
    </div>
  </div>
);

ReviewPackageCaseTitle.propTypes = {
  handlePackageActionModal: PropTypes.func,
  correspondence: PropTypes.object,
  isReadOnly: PropTypes.bool
};

CaseSubTitleScaffolding.propTypes = {
  handlePackageActionModal: PropTypes.func,
  packageActionModal: PropTypes.string,
  isReadOnly: PropTypes.bool
};

CaseTitleScaffolding.propTypes = {
  correspondence_id: PropTypes.number,
  isReadOnly: PropTypes.bool
};

export default ReviewPackageCaseTitle;
