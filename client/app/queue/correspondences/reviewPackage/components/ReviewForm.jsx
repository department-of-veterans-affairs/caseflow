import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import React from 'react';
import { css } from 'glamor';
import TextField from '../../../../components/TextField';
import SearchableDropdown from '../../../../components/SearchableDropdown';
import TextareaField from '../../../../components/TextareaField';
import Button from '../../../../components/Button';
import ApiUtil from '../../../../util/ApiUtil';
import PropTypes from 'prop-types';

const flexDivStyling = css({
  display: 'flex',
});

const mainDiv = css(flexDivStyling, {
  justifyContent: 'space-between',
});

const divideStyling = css(flexDivStyling, {
  width: '50%',
  flexDirection: 'column',
  gap: '30px',
});

const inputStyling = css(flexDivStyling, {
  gap: '20px',
});

const veteranInputStyling = css({
  width: '350px',
});

const tagStyling = css({
  maxWidth: '60rem',
});

const textareaStyling = css({
  maxWidth: '60rem',
});

const textareaWidth = css({
  height: '14rem',
});

export const ReviewForm = (props) => {
  const handleFileNumber = (value) => {
    const updatedReviewDetails = {
      ...props.editableData,
      veteran_file_number: value,
    };

    props.setEditableData(updatedReviewDetails);
  };

  const handleChangeNotes = (value) => {
    const updatedNotes = {
      ...props.editableData,
      notes: value,
    };

    props.setEditableData(updatedNotes);
  };

  const findDefaultVal = (array, id) => {
    const foundItem = array.find((item) => item.id === id);

    return foundItem ? { label: foundItem.name, value: foundItem.name } : null;
  };

  const defaultSelectedValue = findDefaultVal(
    props.reviewDetails.dropdown_values,
    props.editableData.default_select_value
  );

  const generateOptions = (options) =>
    options.map((option) => ({
      value: option.name,
      label: option.name,
      id: option.id,
    }));

  const fullName = (vetaranName) => {
    const {
      first_name: firstName = '',
      middle_initial: middleInitial = '',
      last_name: lastName = '',
    } = vetaranName;

    return `${firstName} ${middleInitial} ${lastName}`;
  };

  const handleSelect = (val) => {
    const updatedSelectedValue = {
      ...props.editableData,
      default_select_value: val.id,
    };

    props.setEditableData(updatedSelectedValue);
  };

  const handleSubmit = async () => {
    const correspondence = props;
    const payloadData = {
      data: {
        correspondence: {
          notes: props.editableData.notes,
          correspondence_type_id: props.editableData.default_select_value,
        },
        veteran: {
          file_number: props.editableData.veteran_file_number,
        },
      },
    };

    await ApiUtil.patch(
      `/queue/correspondence/${correspondence.correspondenceId}`,
      payloadData
    ).then((response) => {
      const { body } = response;

      if (body.status === 'ok') {
        props.fetchData();
        props.setDisableButton((current) => !current);
      }
    });
  };

  return (
    <React.Fragment>
      <div {...flexDivStyling} style={{ gap: '20px', marginTop: '20px' }}>
        <h2>General Information</h2>
        <Button
          name="Save Changes"
          href="/queue/correspondence/12/intake"
          classNames={['usa-button-primary']}
          disabled={!props.disableButton}
          onClick={handleSubmit}
        />
      </div>
      <AppSegment filledBackground noMarginTop>
        <main {...mainDiv}>
          <div {...divideStyling}>
            <div {...inputStyling}>
              <TextField
                label="Veteran file number"
                value={props.editableData.veteran_file_number}
                onChange={handleFileNumber}
              />
              <TextField
                label="Veteran name"
                value={fullName(props.reviewDetails.veteran_name)}
                readOnly
                inputStyling={veteranInputStyling}
              />
            </div>
            <SearchableDropdown
              name="correspondence-dropdown"
              label="Correspondence Type"
              styling={tagStyling}
              value={defaultSelectedValue}
              options={generateOptions(props.reviewDetails.dropdown_values)}
              onChange={handleSelect}
            />
          </div>
          <div {...divideStyling}>
            <div>
              <TextareaField
                name="Notes"
                styling={textareaStyling}
                textAreaStyling={textareaWidth}
                value={props.editableData.notes}
                onChange={handleChangeNotes}
              />
            </div>
          </div>
        </main>
      </AppSegment>
    </React.Fragment>
  );
};

ReviewForm.propTypes = {
  reviewDetails: PropTypes.shape({
    veteran_name: PropTypes.shape({
      first_name: PropTypes.string,
      middle_initial: PropTypes.string,
      last_name: PropTypes.string,
    }),
    dropdown_values: PropTypes.array,
    default_select_value: PropTypes.string,
  }),
  editableData: PropTypes.shape({
    notes: PropTypes.string,
    veteran_file_number: PropTypes.string,
    default_select_value: PropTypes.number,
  }),
  disableButton: PropTypes.bool,
  setEditableData: PropTypes.func,
  setDisableButton: PropTypes.func,
  fetchData: PropTypes.func,
};

export default ReviewForm;
