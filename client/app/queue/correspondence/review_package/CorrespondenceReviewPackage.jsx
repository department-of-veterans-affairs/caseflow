import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useEffect, useState } from 'react';
import ReviewPackageData from './ReviewPackageData';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import ReviewForm from './ReviewForm';
import { CmpDocuments } from './CmpDocuments';
import ApiUtil from '../../../util/ApiUtil';
import PropTypes from 'prop-types';
import { useHistory } from 'react-router';

export const CorrespondenceReviewPackage = (props) => {
  const [reviewDetails, setReviewDetails] = useState({
    veteran_name: {},
    dropdown_values: [],
  });
  const [editableData, setEditableData] = useState({
    notes: '',
    veteran_file_number: '',
    default_select_value: ''
  });
  const [apiResponse, setApiResponse] = useState(null);
  const [correspondenceDocuments, setCorrespondenceDocuments] = useState([]);
  const [selectedCorrespondence, setSelectedCorrespondence] = useState(null);
  const [packageDocumentType, setPackageDocumentType] = useState(null);
  const [disableButton, setDisableButton] = useState(false);
  const [showModal, setShowModal] = useState(false);

  const history = useHistory();
  const fetchData = async () => {
    const correspondence = props;

    const response = await ApiUtil.get(
      `/queue/correspondence/${correspondence.correspondenceId}`
    );

    setApiResponse(response.body.general_information);
    const data = response.body.general_information;

    setCorrespondenceDocuments(response.body.correspondence_documents);
    setSelectedCorrespondence(response.body.correspondence);
    setPackageDocumentType(response.body.package_document_type);

    setReviewDetails({
      veteran_name: data.veteran_name || {},
      dropdown_values: data.correspondence_types || [],
    });

    setEditableData({
      notes: data.notes,
      veteran_file_number: data.file_number,
      default_select_value: data.correspondence_type_id,
    });
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleModalClose = () => {
    setShowModal(!showModal);
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

  useEffect(() => {
    if (apiResponse) {
      const hasChanged = isEditableDataChanged();

      setDisableButton(hasChanged);
    }
  }, [editableData, apiResponse]);

  const intakeLink = `/queue/correspondence/${props.correspondenceId}/intake`;

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
        <ReviewPackageData
          correspondence={selectedCorrespondence}
          packageDocumentType={packageDocumentType} />
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
        <CmpDocuments documents={correspondenceDocuments} />
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
  correspondenceId: PropTypes.string
};

export default CorrespondenceReviewPackage;
