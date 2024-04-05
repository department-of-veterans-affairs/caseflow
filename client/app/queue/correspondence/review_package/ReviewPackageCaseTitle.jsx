import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import Button from '../../../components/Button';
import SearchableDropdown from '../../../components/SearchableDropdown';
import RemovePackageModal from '../component/RemovePackageModal';
import ReassignPackageModal from '../component/ReassignPackageModal';

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
      <CaseTitleScaffolding
        {...props}
      />
      <CaseSubTitleScaffolding
        {...props}
      />
    </div>
  );
};

const CaseTitleScaffolding = (props) => {

  const [modalRemoveState, setRemoveModalState] = useState(false);
  const [modalReassignState, setReassignModalState] = useState(false);

  const openRemoveModal = () => {
    setRemoveModalState(true);
  };
  const closeRemoveModal = () => {
    setRemoveModalState(false);
  };
  const openReassignModal = () => {
    setReassignModalState(true);
  };
  const closeReassignModal = () => {
    setReassignModalState(false);
  };

  return (
    <div {...containingDivStyling}>
      <h1 {...headerStyling}>{COPY.CORRESPONDENCE_REVIEW_PACKAGE_TITLE}</h1>

      <span {...removebotton}>
        { (props.isReadOnly && !props.isReassignPackage && props.userIsSupervisor) &&
          <Button
            name="Review removal request"
            styling={{ style: { marginRight: '2rem', padding: '15px', fontSize: 'larger' } }}
            classNames={['usa-button-primary']}
            onClick={
              openRemoveModal
            }
          />
        }
        { (props.isReadOnly && props.isReassignPackage && (props.userIsSuperuser || props.userIsSupervisor)) &&
          <Button
            name="Review reassign request"
            styling={{ style: { marginRight: '2rem', padding: '15px', fontSize: 'larger' } }}
            classNames={['usa-button-primary']}
            onClick={
              openReassignModal
            }
          />
        }
      </span>
      { modalRemoveState &&
      <RemovePackageModal
        modalState={modalRemoveState}
        setModalState={setRemoveModalState}
        onCancel={closeRemoveModal}
        reviewDetails={props.reviewDetails}
        correspondence_id = {props.correspondence_id} />
      }
      { modalReassignState &&
      <ReassignPackageModal
        modalState={modalReassignState}
        setModalState={setReassignModalState}
        onCancel={closeReassignModal}
        correspondence_id = {props.correspondence_id}
        mailTeamUsers={props.mailTeamUsers} />
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
  reviewDetails: PropTypes.object,
  handlePackageActionModal: PropTypes.func,
  mailTeamUsers: PropTypes.array,
  correspondence: PropTypes.object,
  isReadOnly: PropTypes.bool,
  isReassignPackage: PropTypes.bool,
  userIsSupervisor: PropTypes.bool,
  userIsSuperuser: PropTypes.bool
};

CaseSubTitleScaffolding.propTypes = {
  handlePackageActionModal: PropTypes.func,
  mailTeamUsers: PropTypes.array,
  packageActionModal: PropTypes.string,
  isReadOnly: PropTypes.bool,
  userIsSupervisor: PropTypes.bool,
  userIsSuperuser: PropTypes.bool
};

CaseTitleScaffolding.propTypes = {
  correspondence_id: PropTypes.number,
  mailTeamUsers: PropTypes.array,
  reviewDetails: PropTypes.object,
  isReadOnly: PropTypes.bool,
  isReassignPackage: PropTypes.bool,
  userIsSupervisor: PropTypes.bool,
  userIsSuperuser: PropTypes.bool
};

export default ReviewPackageCaseTitle;
