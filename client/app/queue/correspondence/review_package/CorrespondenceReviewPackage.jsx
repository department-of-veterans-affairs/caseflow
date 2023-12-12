import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useEffect, useState } from 'react';
import ReviewPackageData from './ReviewPackageData';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import ReviewForm from './ReviewForm';
import CorrespondencePdfUI from '../pdfPreview/CorrespondencePdfUI';
import { CmpDocuments } from './CmpDocuments';
import ApiUtil from '../../../util/ApiUtil';
import PropTypes from 'prop-types';
import { setFileNumberSearch, doFileNumberSearch } from '../../../intake/actions/intake';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { useHistory } from 'react-router';
import PackageActionModal from '../modals/PackageActionModal';

export const CorrespondenceReviewPackage = (props) => {
  const [reviewDetails, setReviewDetails] = useState({
    veteran_name: {},
    dropdown_values: [],
  });
  const [editableData, setEditableData] = useState({
    notes: '',
    veteran_file_number: '',
    default_select_value: null
  });
  const [apiResponse, setApiResponse] = useState(null);
  const [disableButton, setDisableButton] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [packageActionModal, setPackageActionModal] = useState(null);
  const [selectedId, setSelectedId] = useState(0);

  const history = useHistory();
  const fetchData = async () => {
    const correspondence = props;

    try {
      const response = await ApiUtil.get(
        `/queue/correspondence/${correspondence.correspondence_uuid}`
      );

      setApiResponse(response.body.general_information);
      const data = response.body.general_information;

      setReviewDetails({
        veteran_name: data.veteran_name || {},
        dropdown_values: data.correspondence_types || [],
      });

      setEditableData({
        notes: data.notes,
        veteran_file_number: data.file_number,
        default_select_value: data.correspondence_type_id,
      });
    } catch (error) {
      throw error();
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleModalClose = () => {
    setShowModal(!showModal);
  };

  const handlePackageActionModal = (value) => {
    setPackageActionModal(value);
  };

  const handleReview = () => {
    history.push('/queue/correspondence');
  };

  const isEditableDataChanged = () => {
    const notesChanged = editableData.notes !== apiResponse.notes;
    const fileNumberChanged = editableData.veteran_file_number !== apiResponse.file_number;
    const selectValueChanged = editableData.default_select_value !== apiResponse.correspondence_type_id;

    return notesChanged || fileNumberChanged || selectValueChanged;
  };

  const intakeAppeal = async () => {
    props.setFileNumberSearch(editableData.veteran_file_number);
    try {
      await props.doFileNumberSearch('appeal', editableData.veteran_file_number, true);
      window.location.href = '/intake/review_request';
    } catch (error) {
      console.error(error);
    }
  };

  useEffect(() => {
    if (apiResponse) {
      const hasChanged = isEditableDataChanged();

      setDisableButton(hasChanged);
    }
  }, [editableData, apiResponse]);

  const intakeLink = `/queue/correspondence/${props.correspondence_uuid}/intake`;

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle handlePackageActionModal={handlePackageActionModal} />
        <ReviewPackageData
          correspondence={props.correspondence}
          packageDocumentType={props.packageDocumentType}
        />
        {packageActionModal &&
          <PackageActionModal
            packageActionModal={packageActionModal}
            closeHandler={handlePackageActionModal}
          />
        }
        <ReviewForm
          {...{
            reviewDetails,
            setReviewDetails,
            editableData,
            setEditableData,
            disableButton,
            setDisableButton,
            fetchData,
            showModal,
            handleModalClose,
            handleReview
          }}
          {...props}
        />
        <CmpDocuments documents={props.correspondenceDocuments} selectedId={selectedId} setSelectedId={setSelectedId} />
        <CorrespondencePdfUI documents={props.correspondenceDocuments} selectedId={selectedId} />
      </AppSegment>
      <div className="cf-app-segment">
        <div className="cf-push-left">
          <Button
            name="Cancel"
            classNames={['cf-btn-link']}
            onClick={handleModalClose}
          />
        </div>
        <div className="cf-push-right">
          <Button
            name="Intake appeal"
            styling={{ style: { marginRight: '2rem' } }}
            classNames={['usa-button-secondary']}
            onClick={intakeAppeal}
          />
          <a href={intakeLink}>
            {/* hard coded UUID to link to multi_correspondence.rb data */}
            <Button
              name="Create record"
              classNames={['usa-button-primary']}
              href={intakeLink}
            />
          </a>
        </div>
      </div>
    </React.Fragment>
  );
};

CorrespondenceReviewPackage.propTypes = {
  correspondence_uuid: PropTypes.string,
  correspondence: PropTypes.object,
  correspondenceDocuments: PropTypes.arrayOf(PropTypes.object),
  packageDocumentType: PropTypes.object,
  veteranInformation: PropTypes.object,
  setFileNumberSearch: PropTypes.func,
  doFileNumberSearch: PropTypes.func
};

const mapStateToProps = (state) => ({
  correspondence: state.reviewPackage.correspondence,
  correspondenceDocuments: state.reviewPackage.correspondenceDocuments,
  packageDocumentType: state.reviewPackage.packageDocumentType,
  veteranInformation: state.reviewPackage.veteranInformation
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setFileNumberSearch,
  doFileNumberSearch
}, dispatch);

export default connect(
  mapStateToProps,
  mapDispatchToProps,
)(CorrespondenceReviewPackage);
