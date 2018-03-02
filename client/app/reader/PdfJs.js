const MAX_PAGE_RENDER_COUNT = 1;

let pageArray = [];
let currentlyRenderingPage = null;
let renderTask = null;

const renderNextPage = () => {
  if (currentlyRenderingPage) {
    return;
  }

  let maxPriority = Number.MIN_SAFE_INTEGER;
  let maxIndex = -1;

  pageArray.forEach((value, index) => {
    if (value.priority > maxPriority) {
      maxIndex = index;
      maxPriority = value.priority;
    }
  });

  if (maxIndex >= 0) {
    const page = pageArray.splice(maxIndex, 1)[0];

    currentlyRenderingPage = page.pageIndex;
    console.log("RENDERING page", page.pageIndex);
    renderTask = page.page.render(page.options);
    renderTask.then(() => {
      page.resolve();
      currentlyRenderingPage = null;
      renderNextPage();
    }, () => {
      page.reject();
      currentlyRenderingPage = null;
      renderNextPage();
    });
  }
};

export const changePriority = (pageIndex, priority) => {
  pageArray.forEach((page) => {
    if (page.pageIndex === pageIndex) {
      page.priority = priority;
    }
  });
};

export const removePageFromRenderQueue = (pageIndex) => {
  if (renderTask && pageIndex === currentlyRenderingPage) {
    renderTask.cancel();
    console.log("TOTALLY CANCELLED");
  }
  pageArray = pageArray.filter((page) => page.pageIndex !== pageIndex);
};

export const addPageToRenderQueue = (page, options, pageIndex, priority) => {
  return new Promise((resolve, reject) => {
    pageArray.push({
      page,
      options,
      pageIndex,
      priority,
      resolve,
      reject
    });

    // console.log('RENDER QUEUE', pageArray);

    renderNextPage();
  });
};
