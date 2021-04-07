import React from 'react';
import { useHistory, useParams } from 'react-router';
import { useDispatch, useSelector } from 'react-redux';
import { format } from 'date-fns';

import { appealWithDetailSelector } from 'app/queue/selectors';
import { GrantedSubstitutionForm } from './GrantedSubstitutionBasicsForm';

import { updateData, stepForward } from './grantedSubstitution.slice';

export const GrantedSubstitutionBasicsView = () => {
  const { appealId } = useParams();
  const dispatch = useDispatch();
  const history = useHistory();
  const appeal = useSelector((state) =>
    appealWithDetailSelector(state, { appealId })
  );

  const { formData: prevValues } = useSelector((state) => state.grantedSubstitution);

  const handleCancel = () => history.push(`/queue/appeals/${appealId}`);
  const handleSubmit = async (formData) => {
    // Here we'll dispatch action to update Redux store with our form data
    // Initially, we may also dispatch async thunk action to submit the basics to the backend because of how stories are sliced

    dispatch(updateData({
      formData: {
        ...formData,
        substitutionDate: format(formData.substitutionDate, 'yyyy-MM-dd'),
      },
    }));
  };

  return (
    <GrantedSubstitutionForm onCancel={handleCancel} onSubmit={handleSubmit} />
  );
};
