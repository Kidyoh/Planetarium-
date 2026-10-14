#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

// Procedural planet renderer. Every body in the app (planets, moons, the Sun)
// is drawn by this one shader, so no texture images ship with the APK.

uniform vec2 uCenter;    // sphere centre in local px
uniform float uRadius;   // sphere radius in px
uniform float uRot;      // spin angle (radians)
uniform float uTime;     // seconds, for weather / turbulence
uniform float uType;     // surface model, see BodyType in Dart
uniform vec3 uLight;     // light direction, screen space (y up, z to viewer)
uniform vec3 uColA;
uniform vec3 uColB;
uniform vec3 uAtmo;
uniform float uAtmoStr;
uniform vec2 uRing;      // inner/outer ring radius in sphere radii (0 = none)
uniform float uRingTilt; // ring opening angle
uniform float uTilt;     // axial tilt in the screen plane
uniform float uSeed;
uniform float uOpacity;

out vec4 fragColor;

float hash(vec3 p) {
  p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
  p *= 17.0;
  return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
  vec3 i = floor(x);
  vec3 f = fract(x);
  f = f * f * (3.0 - 2.0 * f);
  return mix(
    mix(mix(hash(i + vec3(0.0, 0.0, 0.0)), hash(i + vec3(1.0, 0.0, 0.0)), f.x),
        mix(hash(i + vec3(0.0, 1.0, 0.0)), hash(i + vec3(1.0, 1.0, 0.0)), f.x), f.y),
    mix(mix(hash(i + vec3(0.0, 0.0, 1.0)), hash(i + vec3(1.0, 0.0, 1.0)), f.x),
        mix(hash(i + vec3(0.0, 1.0, 1.0)), hash(i + vec3(1.0, 1.0, 1.0)), f.x), f.y),
    f.z);
}

float fbm(vec3 p) {
  float a = 0.5;
  float s = 0.0;
  for (int i = 0; i < 5; i++) {
    s += a * noise(p);
    p = p * 2.03 + vec3(1.7, 9.2, 3.1);
    a *= 0.5;
  }
  return s;
}

// Cellular craters: bowls are darkened, rims brightened on the lit side.
float craters(vec3 p, vec3 lightT) {
  vec3 i = floor(p);
  vec3 f = fract(p);
  float res = 0.0;
  for (int z = -1; z <= 1; z++) {
    for (int y = -1; y <= 1; y++) {
      for (int x = -1; x <= 1; x++) {
        vec3 b = vec3(float(x), float(y), float(z));
        vec3 c = i + b;
        float exists = step(0.45, hash(c + 31.7));
        vec3 o = vec3(hash(c), hash(c + 13.1), hash(c + 27.7)) * 0.6 + 0.2;
        float sz = 0.18 + 0.3 * hash(c + 5.3);
        vec3 dv = (b + o - f) / sz;
        float d = length(dv);
        float bowl = smoothstep(1.0, 0.2, d);
        float rim = smoothstep(0.7, 1.0, d) * smoothstep(1.35, 1.0, d);
        float side = dot(normalize(dv + 1e-4), lightT);
        res += exists * (-0.28 * bowl * (0.6 - 0.4 * side) + 0.22 * rim * (0.5 - 0.5 * side));
      }
    }
  }
  return res;
}

vec3 rotY(vec3 v, float a) {
  float c = cos(a);
  float s = sin(a);
  return vec3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z);
}

void main() {
  vec2 fc = FlutterFragCoord().xy;
  vec2 p = (fc - uCenter) / uRadius;
  p.y = -p.y;

  // Axial tilt: rotate the view so the body's poles lean.
  float ct = cos(uTilt);
  float st = sin(uTilt);
  vec2 q = vec2(ct * p.x - st * p.y, st * p.x + ct * p.y);
  vec3 L = normalize(uLight);
  L = vec3(ct * L.x - st * L.y, st * L.x + ct * L.y, L.z);

  float r = length(q);
  float px = 1.6 / uRadius;
  bool isStar = uType > 10.5;

  vec3 col = vec3(0.0);
  float alpha = 0.0;
  float sphereZ = -10.0;

  if (r < 1.0) {
    float z = sqrt(1.0 - r * r);
    sphereZ = z;
    vec3 N = vec3(q, z);
    vec3 T = rotY(N, uRot) + vec3(uSeed);
    vec3 Tn = rotY(N, uRot);
    vec3 LT = rotY(L, uRot);
    float lat = Tn.y;

    vec3 surf = vec3(0.5);
    float spec = 0.0;
    float emit = 0.0;
    float limb = 0.0;

    if (uType < 0.5) {
      // Mercury: scorched grey rock, dense craters.
      float f = fbm(T * 3.0);
      surf = mix(uColA, uColB, smoothstep(0.35, 0.7, f));
      surf *= 1.0 + craters(T * 6.0, LT) + (fbm(T * 14.0) - 0.5) * 0.18;
    } else if (uType < 1.5) {
      // Venus: thick sulphuric cloud deck, slow swirling bands.
      vec3 w = T * vec3(1.6, 4.5, 1.6) + vec3(uTime * 0.015, 0.0, 0.0);
      float f = fbm(w + fbm(T * 2.5 + uTime * 0.01) * 1.8);
      surf = mix(uColA, uColB, smoothstep(0.3, 0.75, f));
      limb = 0.25;
    } else if (uType < 2.5) {
      // Earth: oceans, continents, ice, clouds, city lights.
      float h = fbm(T * 2.2);
      float land = smoothstep(0.505, 0.525, h);
      vec3 deep = vec3(0.02, 0.09, 0.25);
      vec3 shallow = vec3(0.05, 0.32, 0.52);
      vec3 ocean = mix(deep, shallow, smoothstep(0.40, 0.505, h));
      float dry = smoothstep(0.35, 0.0, abs(lat - 0.05)) * smoothstep(0.45, 0.6, fbm(T * 4.0 + 7.0));
      vec3 green = mix(vec3(0.13, 0.27, 0.09), vec3(0.28, 0.33, 0.14), fbm(T * 7.0));
      vec3 ground = mix(green, vec3(0.62, 0.5, 0.32), dry);
      ground = mix(ground, vec3(0.4, 0.36, 0.3), smoothstep(0.6, 0.72, h));
      surf = mix(ocean, ground, land);
      float ice = smoothstep(0.80, 0.88, abs(lat) + 0.06 * noise(T * 9.0));
      surf = mix(surf, vec3(0.92, 0.95, 1.0), ice);
      vec3 Tc = rotY(N, uRot * 1.18 + uTime * 0.012) + vec3(uSeed + 3.0);
      float cl = fbm(Tc * 3.2 + vec3(0.0, uTime * 0.004, 0.0));
      float cloud = smoothstep(0.48, 0.72, cl);
      surf = mix(surf, vec3(0.97), cloud * 0.92);
      spec = (1.0 - land) * (1.0 - cloud) * (1.0 - ice);
      float lights = step(0.62, noise(T * 55.0)) * step(0.45, noise(T * 7.0));
      emit = land * (1.0 - ice) * (1.0 - cloud) * lights;
      limb = 0.1;
    } else if (uType < 3.5) {
      // Mars: rust plains, dark albedo features, polar cap.
      float f = fbm(T * 2.4);
      surf = mix(uColA, uColB, smoothstep(0.42, 0.66, f));
      surf *= 0.9 + 0.3 * fbm(T * 9.0);
      surf *= 1.0 + 0.6 * craters(T * 5.0, LT);
      float cap = smoothstep(0.86, 0.92, abs(lat) + 0.04 * noise(T * 12.0));
      surf = mix(surf, vec3(0.95, 0.93, 0.9), cap);
    } else if (uType < 5.5) {
      // Jupiter (4) / Saturn (5): turbulent latitude bands.
      bool jup = uType < 4.5;
      float turb = fbm(T * vec3(2.5, 7.0, 2.5) + vec3(uTime * 0.03, 0.0, 0.0));
      float freq = jup ? 17.0 : 13.0;
      float band = sin(lat * freq + turb * (jup ? 4.5 : 2.2));
      float fine = sin(lat * 47.0 + turb * 6.0) * 0.5 + 0.5;
      surf = mix(uColA, uColB, smoothstep(-0.6, 0.6, band));
      surf *= 0.88 + 0.16 * fine;
      if (jup) {
        vec3 spot = normalize(vec3(0.75, -0.36, 0.55));
        vec3 d = Tn - spot;
        float e = length(vec2(d.x * 0.7 + d.z * 0.7, d.y * 1.9));
        float sw = fbm(Tn * 9.0 + uTime * 0.05);
        surf = mix(surf, vec3(0.72, 0.32, 0.2), smoothstep(0.2, 0.08, e + sw * 0.05));
      }
      limb = 0.35;
    } else if (uType < 7.5) {
      // Uranus (6) / Neptune (7): ice-giant haze with soft bands.
      float turb = fbm(T * vec3(2.0, 6.0, 2.0) + vec3(uTime * 0.02, 0.0, 0.0));
      float band = sin(lat * 10.0 + turb * 3.0) * 0.5 + 0.5;
      float amt = uType < 6.5 ? 0.18 : 0.55;
      surf = mix(uColA, uColB, band * amt);
      if (uType > 6.5) {
        vec3 spot = normalize(vec3(-0.5, -0.4, 0.75));
        float e = length((Tn - spot) * vec3(0.7, 2.0, 0.7));
        surf = mix(surf, uColA * 0.45, smoothstep(0.22, 0.12, e));
        float streak = smoothstep(0.62, 0.8, fbm(T * vec3(1.5, 14.0, 1.5)));
        surf = mix(surf, vec3(0.85, 0.9, 1.0), streak * 0.5);
      }
      limb = 0.45;
    } else if (uType < 8.5) {
      // Rocky moon: maria, highlands, craters at two scales.
      float f = fbm(T * 1.7);
      surf = mix(uColA, uColB, smoothstep(0.48, 0.6, f));
      surf *= 1.0 + craters(T * 6.5, LT) + 0.5 * craters(T * 15.0, LT);
      surf *= 0.92 + 0.16 * fbm(T * 22.0);
    } else if (uType < 9.5) {
      // Icy moon: bright crust laced with reddish fractures.
      float f = fbm(T * 2.0);
      surf = mix(uColA, uColA * 0.82, f);
      float crack = 1.0 - smoothstep(0.0, 0.03, abs(noise(T * 5.0) - 0.5));
      float crack2 = 1.0 - smoothstep(0.0, 0.02, abs(noise(T * 11.0 + 4.0) - 0.5));
      surf = mix(surf, uColB, max(crack, crack2 * 0.7) * 0.8);
      surf *= 1.0 + 0.4 * craters(T * 8.0, LT);
    } else if (uType < 10.5) {
      // Hazy moon (Titan): orange smog, barely visible features.
      float f = fbm(T * vec3(2.0, 4.0, 2.0) + uTime * 0.01);
      surf = mix(uColA, uColB, smoothstep(0.35, 0.7, f) * 0.5);
      limb = 0.4;
    } else {
      // Star: boiling granulation, sunspots, fully emissive.
      vec3 w = T * 7.0 + vec3(uTime * 0.12);
      float g = fbm(w + fbm(T * 3.0 - uTime * 0.05) * 2.0);
      float spots = smoothstep(0.72, 0.8, fbm(T * 2.2 + 11.0));
      surf = mix(uColB, uColA, smoothstep(0.3, 0.75, g));
      surf *= 1.0 - spots * 0.6;
      surf *= mix(0.55, 1.05, pow(z, 0.45));
    }

    if (isStar) {
      col = surf * 1.15;
    } else {
      float ndl = dot(N, L);
      float light = clamp((ndl + 0.06) / 1.06, 0.0, 1.0);
      light = pow(light, 0.85);
      col = surf * (0.025 + light);
      col *= mix(1.0, pow(z, 0.35), limb);
      vec3 H = normalize(L + vec3(0.0, 0.0, 1.0));
      col += spec * pow(max(dot(N, H), 0.0), 60.0) * vec3(1.0, 0.95, 0.85) * 0.7;
      float night = 1.0 - smoothstep(-0.25, 0.02, ndl);
      col += emit * night * vec3(1.0, 0.72, 0.35) * 0.9;
      float fres = pow(1.0 - z, 2.6);
      col += uAtmo * fres * uAtmoStr * smoothstep(-0.35, 0.45, ndl) * 1.4;
    }
    alpha = 1.0 - smoothstep(1.0 - px, 1.0, r);
  }

  // Ring system (Saturn, Uranus).
  if (uRing.y > 0.001) {
    vec3 n = vec3(0.0, cos(uRingTilt), sin(uRingTilt));
    float rz = -(q.y * n.y) / max(n.z, 0.001);
    vec3 P = vec3(q, rz);
    float rr = length(P);
    if (rr > uRing.x && rr < uRing.y) {
      float t = (rr - uRing.x) / (uRing.y - uRing.x);
      float dens = 0.55 + 0.3 * sin(t * 70.0 + noise(vec3(t * 40.0, 0.0, 0.0)) * 3.0)
                 + 0.15 * sin(t * 190.0);
      dens *= smoothstep(0.0, 0.04, t) * smoothstep(1.0, 0.92, t);
      dens *= smoothstep(0.015, 0.035, abs(t - 0.66));
      dens *= mix(0.55, 1.0, smoothstep(0.1, 0.35, t));
      vec3 rc = mix(uColA, uColB, smoothstep(0.2, 0.9, t)) * 1.05;
      float lit = 0.35 + 0.65 * abs(dot(n, L));
      float shadowed = 0.0;
      if (dot(P, L) < 0.0 && length(P - dot(P, L) * L) < 1.0) shadowed = 1.0;
      rc *= lit * mix(1.0, 0.12, shadowed);
      float ra = clamp(dens, 0.0, 1.0) * 0.9;
      bool front = sphereZ < -1.0 || rz > sphereZ;
      if (front) {
        col = mix(col * alpha, rc, ra);
        alpha = ra + alpha * (1.0 - ra);
        col = alpha > 0.0 ? col / alpha : col;
      }
    }
  }

  // Outer atmosphere / corona halo.
  vec3 halo = vec3(0.0);
  float haloA = 0.0;
  if (r >= 1.0 - px) {
    float d = r - 1.0;
    if (isStar) {
      float h = exp(-d * 4.0) * 0.9 + exp(-d * 18.0) * 0.6;
      halo = uAtmo * h;
    } else {
      vec2 dir = q / max(r, 1e-4);
      float side = smoothstep(-0.4, 0.6, dot(vec3(dir, 0.0), L) + L.z * 0.5);
      float h = exp(-max(d, 0.0) * 16.0) * uAtmoStr * side;
      halo = uAtmo * h;
    }
    halo = min(halo, vec3(1.0));
    haloA = max(halo.r, max(halo.g, halo.b));
  }

  vec3 outC = col * alpha + halo * (1.0 - alpha);
  float outA = alpha + haloA * (1.0 - alpha);
  fragColor = vec4(outC, outA) * uOpacity;
}
