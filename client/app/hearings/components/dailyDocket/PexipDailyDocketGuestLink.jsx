/* eslint-disable id-length */
import React from "react";
import PropTypes from "prop-types";
import CopyTextButton from "../../../components/CopyTextButton";
import { GUEST_LINK_LABELS } from "../../constants";

export const PexipDailyDocketGuestLink = ({ linkInfo }) => {
  const containerStyle = {
    marginLeft: "-40px",
    marginRight: "-40px",
  };

  const roomInfoStyle = (index) => ({
    backgroundColor: index === 0 ? "#f1f1f1" : "white",
    display: "grid",
    gridTemplateColumns: "1fr 1fr 1fr 1fr",
    gridTemplateRows: "50px",
    gridGap: "110px",
    justifyItems: "start",
    paddingLeft: "10px",
  });

  // Props needed for the copy text button component
  const CopyTextButtonProps = {
    text: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    label: GUEST_LINK_LABELS.COPY_GUEST_LINK,
    textToCopy: "",
  };

  // Takes pin from guestLink
  // const usePinFromLink = () => guestLink?.match(/pin=\d+/)[0]?.split('=')[1];
  // Takes alias from guestLink
  const useAliasFromLink = (link) => {
    if (link.type === "PexipConferenceLink") {
      return (
        link.alias || link.guestLink?.match(/pin=\d+/)[0]?.split("=")[1] || null
      );
    } else if (link.type === "WebexConferenceLink") {
      const newLink = "instant-usgov";
      return link.alias || newLink || null;
    }

    return null;
  };

  const extractPin = (link) => {
    if (link.type === "PexipConferenceLink") {
      return (
        link.guestPin
      );
    } else if (link.type === "WebexConferenceLink") {
      const pinRegex = /(\d{9})$/;
      const match = link.guestLink.match(pinRegex);
      return match ? match[1] : "";
    }

    return null;
  };

  /**
   * Render information about the guest link
   * @param {conferenceRoom} - The conference link alias
   * @param {pin} - The guest pin
   * @param {roleAccess} - Boolean for if the current user has access to the guest link
   * @returns The room information
   */
  const renderRoomInfo = () => {
    return (
      <div>
        {Object.values(linkInfo).map((link, index) => {
          const { guestPin, guestLink, type } = link;

          CopyTextButtonProps.textToCopy = guestLink || "";

          const alias = useAliasFromLink(link);
          const linkGuestPin = extractPin(link);

          return (
            <div key={index} style={roomInfoStyle(index)}>
              <h3
                style={{
                  width: "350px",
                  display: "flex",
                  marginBottom: "0px",
                  alignItems: "center",
                }}
              >
                {type === "PexipConferenceLink"
                  ? GUEST_LINK_LABELS.PEXIP_GUEST_LINK_SECTION_LABEL
                  : GUEST_LINK_LABELS.WEBEX_GUEST_LINK_SECTION_LABEL}
              </h3>

              <h3
                style={{
                  display: "flex",
                  marginBottom: "0px",
                  alignItems: "center",
                  width: "400px",
                }}
              >
                {GUEST_LINK_LABELS.GUEST_CONFERENCE_ROOM + ":"}
                <span style={{ fontWeight: "normal" }}>{alias || "N/A"}</span>
              </h3>
              <h3
                style={{
                  width: "max-content",
                  display: "flex",
                  alignItems: "center",
                  marginBottom: "0px",
                }}
              >
                {GUEST_LINK_LABELS.GUEST_PIN + ":"}
                {linkGuestPin ? (
                  <span
                    style={{
                      fontWeight: "normal",
                      paddingRight: "10px",
                      display: "flex",
                    }}
                  >
                    {linkGuestPin + "#"}
                  </span>
                ) : (
                  <span
                    style={{
                      fontWeight: "normal",
                      paddingRight: "60px",
                      display: "flex",
                    }}
                  >
                    N/A
                  </span>
                )}
              </h3>
              <h3
                style={{
                  width: "max-content",
                  display: "flex",
                  alignItems: "center",
                  marginBottom: "0px",
                }}
              >
                <CopyTextButton {...CopyTextButtonProps} />
              </h3>
            </div>
          );
        })}
      </div>
    );
  };

  return <div style={containerStyle}>{renderRoomInfo()}</div>;
};

PexipDailyDocketGuestLink.propTypes = {
  linkInfo: PropTypes.shape({
    guestLink: PropTypes.string,
    guestPin: PropTypes.string,
    alias: PropTypes.string,
  }),
};

// instant-usgov

//get guest pin from the end of link - 9 gigits

// {
//   "0": {
//     "hostPin": "8517824",
//     "hostLink": "https://example.va.gov/bva-app/?join=1&media=&escalate=1&conference=BVA0000254@example.va.gov&pin=8517824&role=host",
//     "alias": "BVA0000254@example.va.gov",
//     "guestPin": "1497294444",
//     "guestLink": "https://example.va.gov/sample/?conference=BVA0000254@example.va.gov&pin=1497294444&callType=video",
//     "type": "PexipConferenceLink"
//   },
//   "1": {
//     "hostPin": null,
//     "hostLink": "https://test.webex.com/not-real/j.php?MTID=m671700105",
//     "alias": null,
//     "guestPin": null,
//     "guestLink": "https://test.webex.com/not-real/j.php?MTID=m671700105",
//     "type": "WebexConferenceLink"
//   }
// }

// PEXIP_GUEST_LINK_SECTION_LABEL:
//   WEBEX_GUEST_LINK_SECTION_LABEL:

// 25, 30, 15
