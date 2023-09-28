/* eslint-disable id-length */
import React from "react";
import PropTypes from "prop-types";
import CopyTextButton from "../../../components/CopyTextButton";
import { GUEST_LINK_LABELS } from "../../constants";

export const PexipDailyDocketGuestLink = ({ linkInfo }) => {
  const containerStyle = {
    marginLeft: "-40px",
    marginRight: "-40px",
    // marginBottom: "20px",
  };

  const roomInfoContainerStyle = {
    display: "flex",
    flexDirection: "column",
    flexWrap: "wrap",
    justifyContent: "space-between",
  };

  const roomInfoStyle = (index) => ({
    backgroundColor: index === 0 ? "#f1f1f1" : "white",
    display: "flex",
    justifyContent: "space-between",
    width: "100%",
    padding: "10px 30px 10px 20px",
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
  // const useAliasFromLink = () =>
  //   guestLink
  //     ?.split('&')[0]
  //     ?.match(/conference=.+/)[0]
  //     ?.split('=')[1];

  const h3Elements = {
    width: "max-width",
    display: "flex",
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
      <div style={roomInfoContainerStyle}>
        {Object.values(linkInfo).map((link, index) => {
          const { alias, guestPin, guestLink } = link;
          CopyTextButtonProps.textToCopy = guestLink || "";

          return (
            <div key={index} style={roomInfoStyle(index)}>
              <h3 style={h3Elements}>
                {GUEST_LINK_LABELS.PEXIP_GUEST_LINK_SECTION_LABEL}
              </h3>

              <h3 style={h3Elements}>
                {GUEST_LINK_LABELS.GUEST_CONFERENCE_ROOM}:{" "}
                <span style={{ fontWeight: "normal" }}>{alias || "N/A"}</span>
              </h3>
              <h3 style={h3Elements}>
                {GUEST_LINK_LABELS.GUEST_PIN}:{" "}
                <span style={{ fontWeight: "normal" }}>{guestPin}#</span>
              </h3>
              <h3 style={h3Elements}>
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
