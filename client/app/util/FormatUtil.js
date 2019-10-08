export const formatNameLong = (veteranFirstName, veteranLastName) => (
  `${veteranFirstName} ${veteranLastName}`
);

export const formatNameLongReversed = (veteranFirstName, veteranLastName) => (
  `${veteranLastName}, ${veteranFirstName}`
);

export const formatNameShort = (veteranFirstName, veteranLastName) => (
  `${veteranFirstName[0]}. ${veteranLastName}`
);
