import React, { useContext, useState, useMemo } from 'react';
import PropTypes from 'prop-types';

import QueueFlowPage from '../../components/QueueFlowPage';
import COPY from '../../../../COPY';
import Button from '../../../components/Button';
import { MotionToVacateContext } from './MotionToVacateContext';
import { adminActionTemplate } from '../../colocatedTasks/AddColocatedTaskView';
import { AddColocatedTaskForm } from '../../colocatedTasks/AddColocatedTaskForm';
import styles from './AddAdminActionsView.module.scss';
import Alert from '../../../components/Alert';
// import { useSelector } from 'react-redux';
// import { getAllTasksForAppeal } from '../../selectors';

export const AddAdminActionsView = ({ appeal }) => {
  const [ctx, setCtx] = useContext(MotionToVacateContext);

  const initVals = ctx.adminActions?.length ? [...ctx.adminActions] : [adminActionTemplate()];
  const [adminActions, setAdminActions] = useState(initVals);

  const addItem = () => setAdminActions((prev) => [...prev, adminActionTemplate()]);
  const removeItem = (id) => setAdminActions((prev) => [...prev.filter((item) => item.key !== id)]);
  const updateItem = (value, idx) =>
    setAdminActions((prev) => {
      const updated = [...prev];

      updated[idx] = {
        ...updated[idx],
        ...value
      };

      return updated;
    });

  // TODO: update our error checking to check for duplicates in existing tasks from the appeal, not just ones added in this screen
  // const appealTasks = useSelector((state) => getAllTasksForAppeal(state, { appealId: appeal.id }));
  const dupeError = useMemo(() => {
    // See if uniq set is smaller than array
    return new Set(adminActions.map((item) => item.type + item.instructions)).size !== adminActions.length;
  }, [adminActions]);

  const onSubmit = () => setCtx({ ...ctx, adminActions });

  return (
    <QueueFlowPage
      appealId={appeal.externalId}
      validateForm={() => !dupeError}
      disableNext={dupeError}
      getNextStepUrl={() => ctx.getNextUrl('admin_actions')}
      getPrevStepUrl={() => ctx.getPrevUrl('admin_actions')}
      goToNextStep={() => {
        onSubmit();

        return true;
      }}
    >
      <h1>{COPY.ADD_COLOCATED_TASK_SUBHEAD}</h1>
      <hr />
      <section>
        {dupeError && (
          <Alert title="Error" type="error">
            Duplicate admin actions detected
          </Alert>
        )}
        {adminActions.map((item, idx) => (
          <div className="admin-action-item" key={item.key}>
            <AddColocatedTaskForm onChange={(value) => updateItem(value, idx)} value={item} />
            {adminActions.length > 1 && (
              <Button
                willNeverBeLoading
                linkStyling
                className={styles.remove}
                name={COPY.ADD_COLOCATED_TASK_REMOVE_BUTTON_LABEL}
                onClick={() => removeItem(item.key)}
              />
            )}
          </div>
        ))}
        <div className={styles.controls}>
          <Button
            dangerStyling
            willNeverBeLoading
            name={COPY.ADD_COLOCATED_TASK_ANOTHER_BUTTON_LABEL}
            onClick={addItem}
          />
        </div>
      </section>
    </QueueFlowPage>
  );
};

AddAdminActionsView.propTypes = {
  appeal: PropTypes.object.isRequired
};
