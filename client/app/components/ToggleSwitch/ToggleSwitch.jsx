import React, { useState } from "react";
import styles  from "./ToggleSwitch.module.scss"

export default function ToggleSwitch() {
  const [isOff, setIsOff] = useState(true);
  return (
    <button className={styles.toggleButton} onClick={() => setIsOff(!isOff)}><small className={styles.toggleButtonSpace}></small><span className={ `${styles.toggleButtonText} ${isOff ? styles.switchOff : styles.switchOn}` }>{isOff ? "OFF" : "ON"}</span></button>
  );
}
