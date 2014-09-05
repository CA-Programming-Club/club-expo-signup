// Generated by CoffeeScript 1.8.0
(function() {
  var AudioVisualizer, Firework, ParticleVisualizer, SeededRand, audioVisualizer, fireworks, fireworksName, form, main,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  fireworks = {
    "default": {
      fadeLength: 3,
      fireworkSpeed: 2,
      fireworkAcceleration: 4,
      showShockwave: true,
      showTarget: false,
      particleCount: 30,
      particleSpeed: 5,
      particleSpeedVariance: 10,
      particleWind: 50,
      particleFriction: 5,
      particleGravity: 1,
      flickerDensity: 20,
      hueMin: 0,
      hueMax: 360,
      hueVariance: 30,
      lineWidth: 1,
      clearAlpha: 25
    }
  };

  fireworks.debug = Object.create(fireworks["default"]);

  fireworks.debug.showTarget = true;

  ({
    getDt: function(lastTime) {
      var dt, now;
      now = Date.now();
      dt = (now - lastTime) / 16;
      if (dt > 5) {
        return 5;
      } else {
        return dt;
      }
    }
  });

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

    ParticleVisualizer.prototype.size = 6;

    function ParticleVisualizer(name) {
      var c, cx, data, i, imageData, life, px, py, rx, ry, s, skip, vx, vy, w, x, y, _i, _j, _ref, _ref1;
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
      this.startTime = Date.now();
      this.particles = [];
      skip = 0;
      for (px = _i = 0, _ref = c.width; 0 <= _ref ? _i < _ref : _i > _ref; px = 0 <= _ref ? ++_i : --_i) {
        for (py = _j = 0, _ref1 = c.height; 0 <= _ref1 ? _j < _ref1 : _j > _ref1; py = 0 <= _ref1 ? ++_j : --_j) {
          skip = skip + 1;
          if (skip % this.size) {
            continue;
          }
          i = (px + py * c.width) * 4;
          if (!data[i + 3]) {
            continue;
          }
          x = (innerWidth - c.width) / 2 + 2 + px;
          y = (innerHeight - c.height) / 2 + 2 + py;
          rx = px - c.width / 2;
          ry = py - c.height / 2;
          s = .5 + Math.random() * 3;
          vx = rx / 10 * s;
          vy = ry / 10 * s;
          life = 1.4 - s / 5;
          this.particles.push({
            x: x,
            y: y,
            vx: vx,
            vy: vy,
            life: life
          });
        }
      }
      requestAnimationFrame(this.draw);
    }

    ParticleVisualizer.prototype.draw = function() {
      var h, i, p, t, w;
      w = this.canvas.width = innerWidth;
      h = this.canvas.height = innerHeight;
      t = (Date.now() - this.startTime) / 1000;
      this.cx.fillStyle = '#fff';
      i = this.particles.length;
      while (i--) {
        p = this.particles[i];
        if (t > p.life) {
          this.particles.splice(i, 1);
          continue;
        }
        this.cx.globalAlpha = 1 - (t / p.life);
        this.cx.fillRect(p.x | 0, p.y | 0, this.size - 1, this.size - 1);
        p.vx *= 0.97;
        p.vy *= 0.97;
        p.x += p.vx;
        p.y += p.vy;
      }
      if (this.particles.length) {
        return requestAnimationFrame(this.draw);
      }
    };

    return ParticleVisualizer;

  })();

  SeededRand = (function() {
    function SeededRand(state1, state2) {
      this.state1 = state1;
      this.state2 = state2;
      this.mod1 = 4294967087;
      this.mul1 = 65539;
      this.mod2 = 4294965887;
      this.mul2 = 65537;
      if (typeof this.state1 !== "number") {
        this.state1 = Math.floor(Math.random() * 2147483647);
      }
      if (typeof this.state2 !== "number") {
        this.state2 = this.state1;
      }
      this.state1 = this.state1 % (this.mod1 - 1) + 1;
      this.state2 = this.state2 % (this.mod2 - 1) + 1;
    }

    SeededRand.prototype.nextFloat = function() {
      return (this.randTo(4294965886)) / 4294965885;
    };

    SeededRand.prototype.randRange = function(min, max) {
      return (this.randTo(max - min + 1)) + min;
    };

    SeededRand.prototype.nextInt = function(limit) {
      this.state1 = (this.state1 * this.mul1) % this.mod1;
      this.state2 = (this.state2 * this.mul2) % this.mod2;
      if (this.state1 < limit && this.state2 < limit && this.state1 < this.mod1 % limit && this.state2 < this.mod2 % limit) {
        return random(limit);
      }
      return (this.state1 + this.state2) % limit;
    };

    return SeededRand;

  })();

  main();

  Firework = (function() {
    Firework.prototype.canvas = document.getElementById("firework-canvas");

    function Firework(rand, config) {
      var _i, _ref;
      this.rand = rand;
      this.config = Object.create(config);
      this.cx = this.canvas.getContext("2d");
      this.minX = 0;
      this.maxX = innerWidth;
      this.minDestinationY = innerHeight / 2;
      this.maxDestinationY = innerHeight;
      this.startX = this.rand.randRange(this.minX, this.maxX);
      this.startY = 0;
      this.x = this.startX;
      this.y = this.startY;
      this.hitX = false;
      this.hitY = false;
      this.fadeLength = this.config.fadeLength;
      this.history = [];
      for (_i = 0, _ref = this.fadeLength; 0 <= _ref ? _i < _ref : _i > _ref; 0 <= _ref ? _i++ : _i--) {
        this.history.push({
          x: this.starX,
          y: this.startY
        });
      }
      this.targetX = this.rand.randRange(this.startX - innerWidth / 10, this.startX + innerWidth / 10);
      this.targetY = this.rand.randRange(this.minDestinationY, this.maxDestinationY);
      this.speed = this.config.fireworkSpeed;
      this.angle = Math.atan2(this.targetY - this.startY, this.targetX - this.startX);
      this.shockwaveAngle = this.angle + Math.PI / 2;
      this.acceleration = this.config.fireworkAcceleration / 100;
      this.hue = this.rand.nextInt(this.config.hueMin, this.config.hueMax);
      this.brightness = this.rand.nextInt(0, 50);
      this.alpha = rand.nextInt(50, 100) / 100;
      this.lineWidth = this.config.lineWidth;
      this.targetRadius = 1;
      this.showTarget = this.cofig.showTarget;
      this.lastTime = Date.now();
      requestAnimationFrame(this.update);
    }

    Firework.prototype.update = function() {
      var dt, i, vx, vy, _i, _ref;
      dt = getDt(this.lastTime);
      this.lastTime = Date.now();
      this.cx.lineWidth = this.lineWidth;
      vx = Math.cos(this.angle) * this.speed;
      vy = Math.sin(this.angle) * this.speed;
      this.speed *= 1 + this.acceleration;
      for (i = _i = _ref = this.fadeLength - 1; _ref <= 0 ? _i < 0 : _i > 0; i = _ref <= 0 ? ++_i : --_i) {
        this.history[i] = this.history[i - 1];
      }
      this.history[0] = {
        x: this.x,
        y: this.y
      };
      if (this.showTarget) {
        if (this.targetRadius < 8) {
          this.targetRadius += .25 * dt;
        } else {
          this.targetRadius = dt;
        }
      }
      if (this.startX >= this.targetX) {
        if (this.x + vx <= this.targetX) {
          this.x = this.targetX;
          this.hitX = true;
        } else {
          this.x += vx * dt;
        }
      } else {
        if (this.x + vx >= this.targetX) {
          this.x = this.targetX;
          this.hitX = true;
        } else {
          this.x += vx * dt;
        }
      }
      if (this.startY >= this.targetY) {
        if (this.x + vy <= this.targetY) {
          this.y = this.targetY;
          this.hitY = true;
        } else {
          this.y += vy * dt;
        }
      } else {
        if (this.y + vy >= this.targetY) {
          this.y = this.targetY;
          this.hitY = true;
        } else {
          this.y += vy * dt;
        }
      }
      if (this.hitX && this.hitY) {
        return this.createParticles();
      } else {
        return requestAnimationFrame(this.update);
      }
    };

    Firework.prototype.createParticles = function() {};

    return Firework;

  })();

}).call(this);

//# sourceMappingURL=site.js.map
