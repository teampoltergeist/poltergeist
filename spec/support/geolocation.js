navigator.geolocation =
  {
    getCurrentPosition: function(callback)
    {
      callback({ coords: { latitude: '1', longitude: '-1' } });
    }
  }
