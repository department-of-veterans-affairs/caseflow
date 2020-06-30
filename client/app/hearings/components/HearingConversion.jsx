import React, { useEffect } from "react";
import AppSegment from "@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment";
import PropTypes from "prop-types";
import classnames from "classnames";

import * as DateUtil from "../../util/DateUtil";
import { JudgeDropdown } from "../../components/DataDropdowns/index";
import {
  fullWidth,
  marginTop,
  enablePadding,
  maxWidthFormInput,
  leftAlign,
  helperLabel,
} from "./details/style";
import TextField from "../../components/TextField";

export const LeftAlign = ({ children }) => (
  <div {...leftAlign}>
    {children}
    <div />
  </div>
);

export const AddressLine = ({
  name,
  addressLine1,
  addressState,
  addressCity,
  addressZip,
}) => (
  <div>
    <span {...fullWidth}>{name}</span>
    <span {...fullWidth}>{addressLine1}</span>
    <span {...fullWidth}>
      {addressCity}, {addressState} {addressZip}
    </span>
  </div>
);

export const HelperText = () => (
  <span {...helperLabel}>
    Changes to the email are used to send notifications for this hearing only
  </span>
);

export const DisplayValue = ({ label, children }) => (
  <div {...marginTop(25)}>
    <strong>{label}</strong>
    {children}
  </div>
);

export const VirtualHearingSection = ({ label, children, hide }) =>
  !hide && (
    <React.Fragment>
      <div className="cf-help-divider" />
      <h3>{label}</h3>
      {children}
    </React.Fragment>
  );

export const VirtualHearingEmail = ({ email, label, type, error, update }) =>
  type === "change_from_virtual" ? (
    <DisplayValue label={label}>
      <span {...fullWidth}>{email}</span>
    </DisplayValue>
  ) : (
    <React.Fragment>
      <LeftAlign>
        <TextField
          errorMessage={error}
          name={label}
          value={email}
          required
          strongLabel
          className={[
            classnames("cf-form-textinput", "cf-inline-field", {
              [enablePadding]: error,
            }),
          ]}
          onChange={(appellantEmail) =>
            update("virtualHearing", { appellantEmail })
          }
          inputStyling={maxWidthFormInput}
        />
      </LeftAlign>
      <HelperText />
    </React.Fragment>
  );

export const HearingConversion = ({
  hearing,
  type,
  scheduledFor,
  errors,
  update,
}) => {
  const { virtualHearing } = hearing;

  // Prefill appellant/veteran email address and representative email on mount.
  useEffect(() => {
    // Determine which email to use
    const appellantEmail = hearing.appellantIsNotVeteran
      ? hearing.appellantEmailAddress
      : hearing.veteranEmailAddress;

    // Set the emails if not already set
    update("virtualHearing", {
      [!virtualHearing?.appellantEmail && "appellantEmail"]: appellantEmail,
      [!virtualHearing?.representativeEmail &&
      "representativeEmail"]: hearing.representativeEmailAddress,
    });
  }, []);

  return (
    <AppSegment filledBackground>
      <h1 className="cf-margin-bottom-0">Convert to Virtual Hearing</h1>
      <span>
        Email notifications will be sent to the Veteran, POA / Representative,
        and Veterans Law Judge (VLJ).
      </span>
      <DisplayValue label="Hearing Time">
        <span {...fullWidth}>{DateUtil.formatDateStr(scheduledFor)}</span>
      </DisplayValue>
      <VirtualHearingSection label="Veteran">
        <DisplayValue label="">
          <AddressLine
            name={`${hearing?.veteranFirstName} ${hearing?.veteranLastName}`}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        </DisplayValue>
        <VirtualHearingEmail
          label="Veteran Email"
          email={virtualHearing?.appellantEmail}
          error={errors?.appellantEmail}
          type={type}
          update={update}
        />
      </VirtualHearingSection>
      <VirtualHearingSection label="Power of Attorney">
        <DisplayValue label="Attorney">
          <AddressLine
            name={hearing?.representativeName}
            addressLine1={hearing?.appellantAddressLine1}
            addressState={hearing?.appellantState}
            addressCity={hearing?.appellantCity}
            addressZip={hearing?.appellantZip}
          />
        </DisplayValue>
        <VirtualHearingEmail
          label="POA/Representative Email"
          email={virtualHearing?.representativeEmail}
          error={errors?.representativeEmail}
          type={type}
          update={update}
        />
      </VirtualHearingSection>
      <VirtualHearingSection
        hide={type === "change_from_virtual"}
        label="Veterans Law Judge (VLJ)"
      >
        <LeftAlign>
          <JudgeDropdown
            name="judgeDropdown"
            value={hearing?.judgeId}
            onChange={(judgeId) => update("hearing", { judgeId })}
          />
        </LeftAlign>
        <DisplayValue label="VLJ Email">
          <span {...fullWidth}>{hearing.judge?.email || "N/A"}</span>
        </DisplayValue>
      </VirtualHearingSection>
    </AppSegment>
  );
};

HearingConversion.propTypes = {
  type: PropTypes.string,
  scheduledFor: PropTypes.string,
  errors: PropTypes.object,
  update: PropTypes.func,
  hearing: PropTypes.object,
};
