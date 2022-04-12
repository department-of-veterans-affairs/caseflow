import React from "react";
import classNames from "classnames";
import PropTypes from "prop-types";

import { marginTop, input8px } from "../details/style";
import { VSOHearingEmail } from "./VSOHearingEmail";
import { Timezone } from "../VirtualHearings/Timezone";
import { HelperText } from "../VirtualHearings/HelperText";
import COPY from "../../../../COPY";
import { getAppellantTitle, readOnlyEmails } from "../../utils";

export const VSOEmailNotificationsFields = ({
  errors,
  hearing,
  readOnly,
  update,
  time,
  roTimezone,
}) => {
  const disableField = readOnly || readOnlyEmails(hearing);
  const appellantTitle = getAppellantTitle(hearing?.appellantIsNotVeteran);

  return (
    <React.Fragment>
      <div id="email-section" className="usa-grid">
        <VSOHearingEmail
          required={true}
          disabled={disableField}
          label={`${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          email={hearing?.appellantEmailAddress}
          error={errors?.appellantEmailAddress}
          update={update}
        />
        <HelperText label={COPY.VIRTUAL_HEARING_EMAIL_HELPER_TEXT_VSO} />
        <VSOHearingEmail
          required={true}
          disabled={disableField}
          label={`Confirm ${appellantTitle} Email`}
          emailType="appellantEmailAddress"
          email={hearing?.appellantEmailAddress}
          error={errors?.appellantEmailAddress}
          update={update}
        />
        <div className={classNames('usa-grid', { [marginTop(30)]: true })}{...input8px}>
          <Timezone
            required={true}
            errorMessage={errors?.appellantTz}
            value={hearing?.appellantTz}
            onChange={(appellantTz) => update("hearing", { appellantTz })}
            readOnly={disableField}
            time={time}
            roTimezone={roTimezone}
            name="appellantTz"
            label={`${getAppellantTitle(
              hearing?.appellantIsNotVeteran
            )} Timezone`}
          />
          <HelperText label={COPY.VIRTUAL_HEARING_TIMEZONE_HELPER_TEXT} />
        </div>
      </div>
    </React.Fragment>
  );
};

VSOEmailNotificationsFields.propTypes = {
  requestType: PropTypes.string.isRequired,
  time: PropTypes.string.isRequired,
  roTimezone: PropTypes.string.isRequired,
  appellantTitle: PropTypes.string.isRequired,
  readOnly: PropTypes.bool,
  update: PropTypes.func,
  hearing: PropTypes.object,
  errors: PropTypes.object,
  initialRepresentativeTz: PropTypes.string,
  header: PropTypes.string,
};
