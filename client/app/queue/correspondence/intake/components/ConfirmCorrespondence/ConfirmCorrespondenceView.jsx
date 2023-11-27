import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import { PencilIcon } from '../../../../../components/icons/PencilIcon';
import Button from '../../../../../components/Button';
import CorrespondenceDetailsTable from './CorrespondenceDetailsTable';
import ConfirmTasksNotRelatedToAnAppeal from './ConfirmTasksNotRelatedToAnAppeal';

export const ConfirmCorrespondenceView = (props) => {

  const checkedMailTasks = Object.keys(props.mailTasks).filter((name) => props.mailTasks[name]);

  return (
    <div className="gray-border" style={{ marginBottom: '2rem', padding: '3rem 4rem' }}>
      <h1 style={{ marginBottom: '10px' }}>Review and Confirm Correspondence</h1>
      <p style={{ fontSize: '.85em' }}>
        Review the details below to make sure the information is correct before submitting.
        If you need to make changes, please go back to the associated section.
      </p>
      <br></br>
      <div>
        <CorrespondenceDetailsTable />
      </div>
      <div>
        <div style={{ display: 'flex' }}>
          <h2 style={{ margin: '1px 0 15px 0',
            display: 'inline-block',
            marginLeft: '10px' }}>Completed Mail Tasks</h2>
          <div style={{ marginLeft: 'auto' }}>
            <Button linkStyling onClick={() => props.goToStep(2)}>
              <span {...css({ position: 'absolute' })}><PencilIcon /></span>
              <span {...css({ marginLeft: '20px' })}>Edit Section</span>
            </Button>
          </div>
        </div>
        <div {...css({ backgroundColor: '#f5f5f5', padding: '20px', marginBottom: '20px' })}>
          <div {...css({ borderBottom: '1px solid #d6d7d9',
            padding: '10px 10px',
            marginBottom: '20px',
            fontWeight: 'bold' })}>
            Completed Mail Tasks
          </div>
          {checkedMailTasks.map((name, index, array) => (
            <div
              key={index}
              {...css({
                borderBottom: index === array.length - 1 ? 'none' : '1px solid #d6d7d9',
                padding: '10px 10px',
                marginBottom: '10px',
              })}
            >
              {props.mailTasks[name] && <span>{name}</span>}
            </div>
          ))}
        </div>
      </div>
      <div>
        <ConfirmTasksNotRelatedToAnAppeal />
      </div>
    </div>
  );
};

ConfirmCorrespondenceView.propTypes = {
  goToStep: PropTypes.func,
  mailTasks: PropTypes.objectOf(PropTypes.bool)

};
export default ConfirmCorrespondenceView;
