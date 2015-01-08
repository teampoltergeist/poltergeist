// abort all requests to test.js
orig = Poltergeist.WebPage.prototype.onResourceRequestedNative;
Poltergeist.WebPage.prototype.onResourceRequestedNative = function(data,request) {
  if (/test.js/.test(data.url)) {
    request.abort();
  }
  return orig.apply(this,[data, request]);
};
