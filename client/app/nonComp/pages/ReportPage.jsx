import React from 'react';
import { css } from 'glamor';
import PropTypes from 'prop-types';
import Button from 'app/components/Button';
import NonCompLayout from '../components/NonCompLayout';

const buttonInnerContainerStyle = css({
  display: 'flex',
  gap: '32px'
});

const buttonOuterContainerStyling = css({
  display: 'flex',
  justifyContent: 'space-between',
  marginTop: '4rem'
});

const ReportPageButtons = ({ history }) => {
  return (
    <div {...buttonOuterContainerStyling}>
      <Button
        classNames={['cf-modal-link', 'cf-btn-link']}
        label="cancel-report"
        name="cancel-report"
        onClick={() => history.push('/vha')}
      >
        Cancel
      </Button>
      <div {...buttonInnerContainerStyle}>
        <Button
          classNames={['usa-button']}
          label="clear-filters"
          name="clear-filters"
        >
          Clear filters
        </Button>
        <Button
          classNames={['usa-button']}
          label="generate-report"
          name="generate-report"
        >
          Generate task report
        </Button>
      </div>
    </div>
  );
};

const ReportPage = ({ history }) => {
  return (
    <NonCompLayout buttons={<ReportPageButtons history={history} />}>
      <h1>Generate task report</h1>
    </NonCompLayout>
  );
};

ReportPageButtons.propTypes = {
  history: PropTypes.object,
};

ReportPage.propTypes = {
  history: PropTypes.object,
};

export default ReportPage;
