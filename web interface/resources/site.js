// Generated by CoffeeScript 1.8.0
(function() {
  var AudioVisualizer, ParticleVisualizer, audioVisualizer, fireworksName, form, main,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fireworksName = null;

  audioVisualizer = null;

  form = document.querySelector("form");

  form.addEventListener("submit", function(e) {
    if (fireworksName) {
      return;
    }
    e.preventDefault();
    document.body.classList.add("in-fireworks-show");
    fireworksName = form.name.value;
    setTimeout(function() {
      return audioVisualizer.lightness = 15;
    }, 3000);
    return new ParticleVisualizer(fireworksName);
  });

  main = function() {
    return audioVisualizer = new AudioVisualizer;
  };

  if (this.AudioContext == null) {
    this.AudioContext = this.webkitAudioContext;
  }

  AudioVisualizer = (function() {
    AudioVisualizer.prototype.canvas = document.getElementById("audio-canvas");

    function AudioVisualizer() {
      this.poll = __bind(this.poll, this);
      this.cx = this.canvas.getContext("2d");
      this.context = new AudioContext;
      this.analyser = this.context.createAnalyser();
      navigator.webkitGetUserMedia({
        audio: true
      }, (function(_this) {
        return function(stream) {
          _this.source = _this.context.createMediaStreamSource(stream);
          _this.source.connect(_this.analyser);
          _this.arr = new Uint8Array(Math.floor(_this.analyser.frequencyBinCount * .7));
          return setInterval(_this.poll, 1000 / 60);
        };
      })(this), function(e) {
        return console.log(e);
      });
    }

    AudioVisualizer.prototype.hue = 0;

    AudioVisualizer.prototype.damping = .03;

    AudioVisualizer.prototype.lightness = 30;

    AudioVisualizer.prototype._lightness = 30;

    AudioVisualizer.prototype.poll = function() {
      var h, i, w, x, _i, _len, _ref, _results;
      this.analyser.getByteFrequencyData(this.arr);
      w = this.canvas.width = innerWidth;
      h = this.canvas.height = innerHeight;
      this.hue += .1;
      this._lightness += (this.lightness - this._lightness) * this.damping;
      this.cx.fillStyle = "hsl(" + this.hue + ", 80%, " + this._lightness + "%)";
      _ref = this.arr;
      _results = [];
      for (i = _i = 0, _len = _ref.length; _i < _len; i = ++_i) {
        x = _ref[i];
        x *= .5;
        _results.push(this.cx.fillRect(Math.floor(i * w / this.arr.length), h * (1 - x / 255), Math.ceil(w / this.arr.length), h * x / 255));
      }
      return _results;
    };

    return AudioVisualizer;

  })();

  ParticleVisualizer = (function() {
    ParticleVisualizer.prototype.canvas = document.getElementById("particle-canvas");

    function ParticleVisualizer(name) {
      var c, cx, data, i, imageData, magnitude, rx, ry, skip, tvx, tvy, vMagnitude, w, x, xLoc, y, yLoc, _i, _j, _ref, _ref1;
      this.name = name;
      this.draw = __bind(this.draw, this);
      this.cx = this.canvas.getContext("2d");
      c = document.createElement("canvas");
      cx = c.getContext("2d");
      cx.textBaseline = "alphabetic";
      cx.font = "200 72px Helvetica Neue, sans-serif";
      w = cx.measureText(name).width;
      c.height = 72 * 1.5;
      c.width = w;
      cx.font = "200 72px Helvetica Neue, sans-serif";
      cx.fillStyle = "#fff";
      cx.fillText(name, 0, 75 * 1.05);
      imageData = cx.getImageData(0, 0, c.width, c.height);
      data = imageData.data;
      this.startTime = +(new Date);
      this.particles = [];
      this.size = 5;
      skip = 0;
      for (x = _i = 0, _ref = c.width; 0 <= _ref ? _i < _ref : _i > _ref; x = 0 <= _ref ? ++_i : --_i) {
        for (y = _j = 0, _ref1 = c.height; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; y = 0 <= _ref1 ? ++_j : --_j) {
          skip = skip + 1;
          if (skip % this.size !== 0) {
            continue;
          }
          i = (x + y * c.width) * 4;
          if (!data[i + 3]) {
            continue;
          }
          xLoc = (innerWidth - c.width) / 2 + 2 + x;
          yLoc = (innerHeight - c.height) / 2 + 2 + y;
          rx = xLoc - innerWidth / 2;
          ry = yLoc - innerHeight / 2;
          magnitude = Math.sqrt(rx * rx + ry * ry);
          tvx = 1 * Math.random() * (-20 + (50 / Math.abs(rx))) * (rx / magnitude);
          tvy = 1.5 * Math.random() * (-20 + (50 / Math.abs(ry))) * (ry / magnitude);
          vMagnitude = Math.sqrt(tvx * tvx + tvy * tvy);
          this.particles.push({
            x: xLoc,
            y: yLoc,
            vx: (tvx + 7 * tvx / vMagnitude) * innerWidth / 750,
            vy: (tvy + 7 * tvy / vMagnitude) * innerHeight / 650,
            color: "rgba(" + data[i] + "," + data[i + 1] + "," + data[i + 2] + "," + data[i + 3] + ")"
          });
        }
      }
      setTimeout((function(_this) {
        return function() {
          return _this.cx.clearRect(0, 0, innerWidth, innerHeight, false);
        };
      })(this), 4010);
      requestAnimationFrame(this.draw);
    }

    ParticleVisualizer.prototype.draw = function() {
      var h, p, w, _i, _len, _ref;
      w = this.canvas.width = innerWidth;
      h = this.canvas.height = innerHeight;
      _ref = this.particles;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        p = _ref[_i];
        this.cx.fillStyle = p.color;
        this.cx.fillRect(p.x | 0, p.y | 0, this.size, this.size);
        p.vx *= 0.99;
        p.vy *= 0.99;
        p.x += p.vx;
        p.y += p.vy;
      }
      if ((+(new Date)) - this.startTime < 4000) {
        return requestAnimationFrame(this.draw);
      }
    };

    return ParticleVisualizer;

  })();

  main();

}).call(this);

//# sourceMappingURL=site.js.map