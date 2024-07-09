
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import Button from '../../../components/Button';
import SearchableDropdown from '../../../components/SearchableDropdown';
import RemovePackageModal from '../component/RemovePackageModal';
import ReassignPackageModal from '../component/ReassignPackageModal';

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
    <div className="correspondence-case-title-header-containing-div-styling">
      <h1 className="correspondence-review-package-case-title-header-styling">
        {COPY.CORRESPONDENCE_REVIEW_PACKAGE_TITLE}
      </h1>

      <span className="correspondence-review-package-case-title-remove-button">
        { (
          props.isReadOnly && !props.isReassignPackage &&
          props.userIsInboundOpsSupervisor) &&
          <Button
            name="Review removal request"
            classNames={['usa-button-primary', 'correspondence-review-package-case-title-button-styling']}
            onClick={
              openRemoveModal
            }
          />
        }
        { (
          props.isReadOnly &&
          props.isReassignPackage &&
          (props.isInboundOpsSuperuser || props.userIsInboundOpsSupervisor)) &&
          <Button
            name="Review reassign request"
            classNames={['usa-button-primary, correspondence-review-package-case-title-button-styling']}
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
        blockingTaskId={props.blockingTaskId}
        correspondence_id = {props.correspondence_id} />
      }
      { modalReassignState &&
      <ReassignPackageModal
        modalState={modalReassignState}
        setModalState={setReassignModalState}
        onCancel={closeReassignModal}
        correspondence_id = {props.correspondence_id}
        blockingTaskId={props.blockingTaskId}
        inboundOpsTeamUsers={props.inboundOpsTeamUsers} />
      }
    </div>
  );

};

const CaseSubTitleScaffolding = (props) => (
  <div className="correspondence-list-styling">
    <div className="correspondence-column-styling">
      {COPY.CORRESPONDENCE_REVIEW_PACKAGE_SUB_TITLE}
    </div>
    <div className="correspondence-drop-down-div">
      { (!props.isReadOnly && !props.efolder) &&
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
  inboundOpsTeamUsers: PropTypes.array,
  correspondence: PropTypes.object,
  isReadOnly: PropTypes.bool,
  isReassignPackage: PropTypes.bool,
  userIsInboundOpsSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool
};

CaseSubTitleScaffolding.propTypes = {
  handlePackageActionModal: PropTypes.func,
  inboundOpsTeamUsers: PropTypes.array,
  packageActionModal: PropTypes.string,
  isReadOnly: PropTypes.bool,
  efolder: PropTypes.bool,
  userIsInboundOpsSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool
};

CaseTitleScaffolding.propTypes = {
  correspondence_id: PropTypes.number,
  inboundOpsTeamUsers: PropTypes.array,
  isReadOnly: PropTypes.bool,
  isReassignPackage: PropTypes.bool,
  userIsInboundOpsSupervisor: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  blockingTaskId: PropTypes.number
};

export default ReviewPackageCaseTitle;
