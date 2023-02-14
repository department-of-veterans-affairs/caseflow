import React, { useMemo, useState } from 'react';
import PropTypes from 'prop-types';
import { useDispatch, useSelector } from 'react-redux';
import Checkbox from 'app/components/Checkbox';
import CheckboxGroup from 'app/components/CheckboxGroup';
import Button from 'app/components/Button';
import TextareaField from 'app/components/TextareaField';
import Alert from '../../components/Alert';
import { find, some } from 'lodash';
import { css } from 'glamor';
import { VHA_PROGRAM_OFFICE_OPTIONS, VHA_CAMO_AND_CAREGIVER_OPTIONS } from '../constants';
import { VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE,
  VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE } from '../../../COPY';
import ApiUtil from '../../util/ApiUtil';
import { setSuccessMessage } from '../helpApiSlice';

const checkboxDivStyling = css({
  '& .cf-form-checkboxes': { marginTop: '10px' },
  '& .checkbox': { marginTop: '0px' },
});

// TODO: Make this MembershipRequestForm generic instead of VHA only?
const VhaMembershipRequestForm = () => {

  // Redux selectors
  // TODO: Might move these to a selectors file?
  const programOfficeTeamManagementFeatureToggle = useSelector(
    (state) => state.help.featureToggles.programOfficeTeamManagement
  );

  const userOrganizations = useSelector(
    (state) => state.help.userOrganizations
  );

  const organizationMembershipRequests = useSelector(
    (state) => state.help.organizationMembershipRequests
  );

  const dispatch = useDispatch();

  // Decide what special access checkbox options are available based on the feature toggle.
  // If it is enabled show all program offices, otherwise only show camo and caregiver.
  const specializedAccessOptions = programOfficeTeamManagementFeatureToggle ?
    [...VHA_CAMO_AND_CAREGIVER_OPTIONS, ...VHA_PROGRAM_OFFICE_OPTIONS] :
    VHA_CAMO_AND_CAREGIVER_OPTIONS;

  // TODO: Figure out if Memo matters here or not
  // I dont think it does since useState won't be initialized more than once.
  const parsedIssues = useMemo(() => {
    specializedAccessOptions.reduce((acc, obj) => {
      acc[obj.id] = false;

      return acc;
    }, {});
  }, [specializedAccessOptions]);

  const [vhaAccess, setVhaAccess] = useState(false);
  const [programOfficesAccess, setProgramOfficesAccess] = useState(parsedIssues);
  const [requestReason, setRequestReason] = useState('');

  const onVhaProgramOfficeAccessChange = (evt) => {
    setProgramOfficesAccess({ ...programOfficesAccess, [evt.target.id]: evt.target.checked });
  };

  const memberOrOpenRequestToVha = Boolean(find(userOrganizations, { name: 'Veterans Health Administration' }) ||
   find(organizationMembershipRequests, { name: 'Veterans Health Administration' }));

  let memberOrRequestToProgramOffices = false;

  const alteredOptions = specializedAccessOptions.map((obj) => {
    const foundOrganization = some(userOrganizations, (match) => match.name === obj.name);

    const foundMembershipRequest = some(organizationMembershipRequests, (match) => match.name === obj.name);

    if (foundOrganization || foundMembershipRequest) {
      memberOrRequestToProgramOffices = true;

      return { ...obj, disabled: true };
    }

    return obj;
  });

  const GeneralVHAAccess = ({ vhaMember }) => {
    return <fieldset>
      <legend><strong>General Access</strong></legend>
      <Checkbox
        name="vhaAccess"
        label="VHA"
        disabled={vhaMember}
        onChange={(val) => setVhaAccess(val)}
        value={vhaAccess}
      />
    </fieldset>;
  };

  GeneralVHAAccess.propTypes = {
    vhaMember: PropTypes.bool
  };

  const SpecializedAccess = ({ checkboxOptions }) => {
    return (
      <fieldset>
        <legend><strong>Specialized Access</strong></legend>
        <CheckboxGroup
          name="programOfficesAccess"
          hideLabel
          options={checkboxOptions}
          onChange={(val) => onVhaProgramOfficeAccessChange(val)}
          values={programOfficesAccess}
        />
      </fieldset>
    );
  };

  SpecializedAccess.propTypes = {
    checkboxOptions: PropTypes.arrayOf(
      PropTypes.object
    ).isRequired
  };

  // TODO: add a onsubmit to this button and potentially one to the form?
  const SubmitButton = ({ ...btnProps }) => {
    return (
      <Button type="submit" name="submit-request" {...btnProps}>
      Submit
      </Button>
    );
  };

  const resetMembershipRequestForm = () => {
    setVhaAccess(false);
    setProgramOfficesAccess(parsedIssues);
    setRequestReason('');
  };

  const handleSubmit = (event) => {
    // TODO: handle all of this in a dispatch to the form reducer/thunk/actions
    // dispatchEvent(submitFormAction(formData));
    // Do not need prevent default if I don't use button type=submit, but would need click handler or something.
    event.preventDefault();
    console.log('me submit form real good like');
    const membershipRequests = { vhaAccess, ...programOfficesAccess };
    const { body } = ApiUtil.post(
      '/membership_requests',
      // { data: { vhaAccess, programOfficesAccess, requestReason } },
      { data: { membershipRequests, requestReason } },
    ).then((response) => {
      const { message } = response.body.data;

      console.log(response.body.data);
      alert(message);

      // dispatch(setUserOrganizations(props.userOrganizations));
      dispatch(setSuccessMessage(message));

      // TODO: renable this. It's just annoying for testing though.
      // resetMembershipRequestForm();

      // can dispatch or can just do a normal form submit.
      // I think it doesn't matter which but would change the reload/loading of data.
      // If it's a normal form submit then we probably need an erb file.
    }).
      catch((error) => {
        console.log(error);
        alert(error);
      });
  };

  const anyProgramOfficeSelected = useMemo(() => (
    find(programOfficesAccess, (value) => value === true)),
  [programOfficesAccess]);

  const vhaSelectedOrExistingMember = Boolean(memberOrOpenRequestToVha || vhaAccess);

  const submitDisabled = Boolean(memberOrOpenRequestToVha ?
    (!anyProgramOfficeSelected) :
    (!vhaAccess && !anyProgramOfficeSelected));

  const automaticVhaAccessNotice = anyProgramOfficeSelected && !vhaSelectedOrExistingMember;

  // TODO: Maybe move these strings to the constants file
  // TODO: Fix the page moving for the paragraph notice if I can. It's a bit jarring.
  return (
    <>
      <h1> 1. How do I access the VHA team?</h1>
      <p> If you need access to a VHA team, please fill out the form below. </p>
      <h2> Select which VHA groups you need access to </h2>
      {(memberOrOpenRequestToVha || memberOrRequestToProgramOffices) &&
        <div style={{ marginBottom: '3rem' }}>
          <Alert
            type="info"
            message={VHA_MEMBERSHIP_REQUEST_DISABLED_OPTIONS_INFO_MESSAGE}
          />
        </div>
      }
      <form onSubmit={handleSubmit} className={checkboxDivStyling}>
        <GeneralVHAAccess vhaMember={memberOrOpenRequestToVha} />
        <SpecializedAccess checkboxOptions={alteredOptions} />
        <div style={{ minHeight: '51px' }}>
          { automaticVhaAccessNotice && (<p> {VHA_MEMBERSHIP_REQUEST_AUTOMATIC_VHA_ACCESS_NOTE} </p>)}
        </div>
        <TextareaField
          label="Reason for access"
          name="membership-request-instructions-textBox"
          optional
          value={requestReason}
          onChange={(val) => setRequestReason(val)}
        />
        <SubmitButton disabled={submitDisabled} />
      </form>
    </>
  );
};

export default VhaMembershipRequestForm;
