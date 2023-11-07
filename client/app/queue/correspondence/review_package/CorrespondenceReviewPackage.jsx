import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React, { useEffect, useState } from 'react';
import ReviewPackageCmpInfo from './ReviewPackageCmpInfo';
import ReviewPackageCaseTitle from './ReviewPackageCaseTitle';
import Button from '../../../components/Button';
import ReviewForm from '../../correspondences/reviewPackage/components/ReviewForm';
import ApiUtil from '../../../util/ApiUtil';

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
  const [disableButton, setDisableButton] = useState(false);

  const fetchData = async () => {
    const correspondence = props;

    try {
      const response = await ApiUtil.get(
        `/queue/correspondence/${correspondence.correspondenceId}`
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

  return (
    <React.Fragment>
      <AppSegment filledBackground>
        <ReviewPackageCaseTitle />
        <ReviewPackageCmpInfo {...props} />
        <ReviewForm
          {...{
            reviewDetails,
            setReviewDetails,
            editableData,
            setEditableData,
            disableButton,
            setDisableButton,
            fetchData
          }}
          {...props}
        />
      </AppSegment>
      <div className="cf-app-segment">
        <div className="cf-push-left">
          <a href="/queue/correspondence">
            <Button
              name="Cancel"
              href="/queue/correspondence"
              classNames={['cf-btn-link']}
            />
          </a>
        </div>
        <div className="cf-push-right">
          <Button
            name="Intake appeal"
            styling={{ style: { marginRight: '2rem' } }}
            classNames={['usa-button-secondary']}
          />
          <a href="/queue/correspondence/12/intake">
            <Button
              name="Create record"
              href="/queue/correspondence/12/intake"
              classNames={['usa-button-primary']}
            />
          </a>
        </div>
      </div>
    </React.Fragment>
  );
};

export default CorrespondenceReviewPackage;
