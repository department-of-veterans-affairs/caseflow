export const formatNameLong = (veteranFirstName, veteranLastName) => (
  `${veteranFirstName} ${veteranLastName}`
);

export const formatNameLongReversed = (veteranFirstName, veteranLastName) => (
  `${veteranLastName}, ${veteranFirstName}`
);

export const formatNameShort = (veteranFirstName, veteranLastName) => (
  `${veteranFirstName[0]}. ${veteranLastName}`
);

export const formatRegionalOfficeList = (regionalOffices) => {
  const centralOffice = (value) => value.state === 'DC' ? 'Central' : `${value.city}, ${value.state}`;

  const regionalOfficeOptions = Object.keys(regionalOffices).map((key) => ({
    label:
      !regionalOffices[key].state && !regionalOffices[key].city ?
        regionalOffices[key].label :
        centralOffice(regionalOffices[key]),
    value: { key, ...regionalOffices[key] },
  }));

  regionalOfficeOptions.sort((first, second) => (first.label < second.label ? -1 : 1));

  return regionalOfficeOptions;
};
